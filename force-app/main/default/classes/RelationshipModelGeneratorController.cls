/**
 * Generate Apex SObject wrappers that provide mutable relationship fields.
 */
public with sharing class RelationshipModelGeneratorController {

    private static final String ONE_INDENT = '    ';

    private static final String[] DEFAULT_TYPES = new String[] {
        'cve__Claim__c',
        'cve__BenefitClaimed__c',
        'cve__Benefit__c',
        'cve__CoverageClaimed__c',
        'cve__Coverage__c',
        'cve__Policy__c',
        'cve__Journal__c',
        'cve__PaymentSpecification__c',
        'cve__ClaimRelationship__c',
        'Contact',
        'Account'
    };

    private static final String[] DEFAULT_EXCLUSIONS = new String[] {
        'cve__Claim__c.cve__PrecedingClaim__c',
        'cve__Claim__c.cve__ClaimantInsuredAccount__c',
        'cve__BenefitClaimed__c.cve__ClaimantInsuredAccount__c',
        'cve__BenefitClaimed__c.cve__ClaimantInsured__c',
        'cve__BenefitClaimed__c.cve__LatestJournal__c',
        'cve__BenefitClaimed__c.cve__LatestPaymentSpecification__c',
        'cve__Benefit__c.cve__BaseBenefit__c',
        'cve__Coverage__c.cve__PercentageOf__c',
        'cve__Journal__c.cve__ClaimantInsuredAccount__c',
        'cve__PaymentSpecification__c.cve__ClaimantInsuredAccount__c',
        'cve__ClaimRelationship__c.cve__AccountWithAccountLabel__c',
        'cve__ClaimRelationship__c.cve__ContactWithContactLabel__c',
        'Contact.AccountId',
        'Contact.cve__Parent__c',
        'Contact.cve__Spouse__c',
        'Account.ParentId'
    };

    // Per SObject
    private class Type {

        RelationshipModelGeneratorController controller;
        SObjectType sobType;
        String[] recordTypeDeveloperNames = new String[] {};
        Relationship[] parents = new Relationship[] {};
        Relationship[] children = new Relationship[] {};

        Type(RelationshipModelGeneratorController controller, SObjectType sobType) {
            this.controller = controller;
            this.sobType = sobType;
            for (RecordTypeInfo rti : sobType.getDescribe().getRecordTypeInfos()) {
                if (rti.isActive() && !rti.isMaster()) {
                    recordTypeDeveloperNames.add(rti.getDeveloperName());
                }
            }
            recordTypeDeveloperNames.sort();
        }

        String sobType() {
            return String.valueOf(sobType).removeStart(controller.namespacePrefixToStrip);
        }

        String factoryMethodName() {
            return 'new' + className();
        }

        String className() {
            return toClassName(sobType);
        }

        String testName() {
            return className().uncapitalize();
        }

        String recordTypeEnumName() {
            return className() + 'RecordType';
        }

        String toClassName(SObjectType t) {
            String s = String.valueOf(t);
            if (s.endswith('__c')) {
                s = s.removeEnd('__c');
                s = s.removeStart(controller.namespacePrefixToStrip);
            } else {
                s = s + 'Wrapper';
            }
            return s;
        }
    }

    // Per relationship
    private class Relationship {

        RelationshipModelGeneratorController controller;

        SObjectType parentSobType;
        SObjectType childSobType;

        SObjectField relationshipField;
        String relationshipName;

        // Set later
        SObjectField parentRelationshipField;
        Boolean deduplicate = false;

        Relationship(RelationshipModelGeneratorController controller, SObjectType parentSobType, SObjectType childSobType, SObjectField relationshipField, String relationshipName) {
            this.controller = controller;
            this.parentSobType = parentSobType;
            this.childSobType = childSobType;
            this.relationshipField = relationshipField;
            this.relationshipName = relationshipName;
        }

        String parentFactoryMethodName() {
            return 'new' + parentClassName();
        }

        String childFactoryMethodName() {
            return 'new' + childClassName();
        }

        String parentSobType() {
            return String.valueOf(parentSobType).removeStart(controller.namespacePrefixToStrip);
        }

        String childSobType() {
            return String.valueOf(childSobType).removeStart(controller.namespacePrefixToStrip);
        }

        String parentRelationshipName() {
            return stripRelationshipName(String.valueOf(parentRelationshipField)).uncapitalize();
        }

        String rawParentRelationshipName() {
            return toRelationshipName(parentRelationshipField);
        }

        String childRelationshipName() {
            return stripRelationshipName(relationshipName).uncapitalize() + (deduplicate ? 'Children' : '');
        }

        String rawChildRelationshipName() {
            return relationshipName;
        }

        String parentMethodName() {
            return 'setParent' + stripRelationshipName(String.valueOf(relationshipField));
        }

        String childMethodName() {
            return 'addChildTo' + stripRelationshipName(relationshipName) + (deduplicate ? 'Children' : '');
        }

        String parentClassName() {
            return toClassName(parentSobType);
        }

        String childClassName() {
            return toClassName(childSobType);
        }

        String stripRelationshipName(String s) {
            s = s.removeEnd('__c');
            s = s.removeEnd('__r');
            s = s.removeStart(controller.namespacePrefixToStrip);
            return s;
        }

        String toRelationshipName(SObjectField f) {
            String s = String.valueOf(f);
            if (s.endsWith('__c')) {
                return s.removeEnd('__c') + '__r';
            }
            return s;
        }

        String toClassName(SObjectType t) {
            String s = String.valueOf(t);
            if (s.endswith('__c')) {
                s = s.removeEnd('__c');
                s = s.removeStart(controller.namespacePrefixToStrip);
            } else {
                s = s + 'Wrapper';
            }
            return s;
        }
    }

    private transient Set<SObjectType> sobTypes {
        get {
            if (sobTypes == null) {
                sobTypes = new Set<SObjectType>();

                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                for (String type : types.split('\n')) {
                    type = type.trim();
                    SObjectType t = gd.get(type);
                    if (t != null) {
                        sobTypes.add(t);
                    } else {
                        addError('Did not recognise SObjectType ' + type + ' so no code generated for that');
                    }
                }
            }
            return sobTypes;
        }
        set;
    }

    private transient Set<SObjectField> excludedFields {
        get {
            if (excludedFields == null) {
                excludedFields = new Set<SObjectField>();

                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                for (String exclusion : exclusions.split('\n')) {
                    exclusion = exclusion.trim();
                    String[] parts = exclusion.split('\\.');
                    if (parts.size() == 2) {
                        String type = parts[0];
                        String field = parts[1];
                        SObjectType t = gd.get(type);
                        if (t != null) {
                            Map<String, SObjectField> m = t.getDescribe().fields.getMap();
                            SObjectField f = m.get(field);
                            if (f != null) {
                                excludedFields.add(f);
                            } else {
                                addError('Did not recognise SObjectField ' + field + ' so exclusion ' + exclusion + ' ignored');
                            }
                        } else {
                            addError('Did not recognise SObjectType ' + type + ' so exclusion ' + exclusion + ' ignored');
                        }
                    } else {
                        addError('Could not parse exclusion ' + exclusion + ' so ignored');
                    }
                }
            }
            return excludedFields;
        }
        set;
    }

    private transient Map<SObjectType, Type> typeInfo {
        get {
            if (typeInfo == null) {
                typeInfo = new Map<SObjectType, Type>();

                for (SObjectType sobType : sobTypes) {
                    typeInfo.put(sobType, new Type(this, sobType));
                }

                // Relationship name from child relationships needed for parent relationships
                Map<SObjectField, Relationship> fieldInfo = new Map<SObjectField, Relationship>();

                // Child info
                for (SObjectType sobType : sobTypes) {
                    Type t = typeInfo.get(sobType);

                    for (ChildRelationship c : sobType.getDescribe().getChildRelationships()) {
                        SObjectType ct = c.getChildSObject();
                        if (sobTypes.contains(ct) && c.getRelationshipName() != null && !excludedFields.contains(c.getField())) {
                            Relationship r = new Relationship(this, sobType, ct, c.getField(), c.getRelationshipName());
                            t.children.add(r);
                            fieldInfo.put(c.getField(), r);
                        }
                    }
                }

                // Parent info
                for (SObjectType sobType : sobTypes) {
                    Type t = typeInfo.get(sobType);

                    for(SObjectField f : sobType.getDescribe().fields.getMap().values()) {
                        if (!excludedFields.contains(f)) {
                            DescribeFieldResult dfr = f.getDescribe();
                            if (dfr.getType() == DisplayType.REFERENCE) {
                                for (SObjectType pt : dfr.getReferenceTo()) {
                                    if (sobTypes.contains(pt)) {
                                        // Instance shared
                                        Relationship r = fieldInfo.get(f);
                                        if (r != null) {
                                            t.parents.add(r);
                                            // Fill in last bit of info
                                            r.parentRelationshipField = f;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Possible that there are duplicate relationship names between the parent and child set so de-duplicate
                for (SObjectType sobType : sobTypes) {
                    Type t = typeInfo.get(sobType);

                    Map<String, Relationship> parentNames = new Map<String, Relationship>();
                    for (Relationship p : t.parents) {
                        parentNames.put(p.parentRelationshipName(), p);
                    }

                    for (Relationship c : t.children) {
                        if (parentNames.containsKey(c.childRelationshipName())) {
                            c.deduplicate = true;
                        }
                    }
                }

            }

            return typeInfo;
        }
        set;
    }

    private transient String[] lines {
        get {
            if (lines == null) lines = new String[] {};
            return lines;
        }
        set;
    }

    private transient Integer indent {
        get {
            if (indent == null) indent = 0;
            return indent;
        }
        set;
    }

    private String classModifier {
        get {
            return propertiesGlobal ||  methodsGlobal ? 'global' : 'public';
        }
    }

    private String propertyModifier {
        get {
            return propertiesGlobal ? 'global' : 'public';
        }
    }

    private String methodModifier {
        get {
            return methodsGlobal ? 'global' : 'public';
        }
    }

    public Integer codeLines {get; private set;}
    public Integer testLines {get; private set;}

    // UI form fields
    public String outerClassName {get; set;}
    public String namespacePrefixToStrip {get; set;}
    public String types {get; set;}
    public String exclusions {get; set;}
    public Boolean propertiesGlobal {get; set;}
    public Boolean methodsGlobal {get; set;}
    public String code {get; set;}
    public String test {get; set;}

    public RelationshipModelGeneratorController() {

        outerClassName = 'EligibilityModel';
        namespacePrefixToStrip = 'cve__';

        types = String.join(DEFAULT_TYPES, '\n');
        exclusions = String.join(DEFAULT_EXCLUSIONS, '\n');

        propertiesGlobal = false;
        methodsGlobal = false;

        codeLines = 0;
        testLines = 0;
    }

    public PageReference generate() {

        lines.clear();
        outerClass();
        code = String.join(lines, '\n');
        codeLines = lines.size();

        lines.clear();
        testClass();
        test = String.join(lines, '\n');
        testLines = lines.size();

        return null;
    }

    // Adds a line respecting the indent
    private void add(String line) {
        lines.add(ONE_INDENT.repeat(indent) + line);
    }

    // Adds a blank line
    private void blank() {
        lines.add('');
    }

    //
    // Code generation
    //

    private void outerClass() {

        add('/*');
        add(' * Generated by the ModelGenerator page - do not edit directly.');
        add(' * ');
        add(' * Simple type-safe SObject wrapper classes that hold the parent/child relationships');
        add(' * to use in place of the __r properties (unusable in general as the collections are immutable).');
        add(' * Adding a parent or a child also populates the reverse relationship.');
        add(' * The SObject is exposed so its non-relationship fields can be directly accessed.');
        add(' * Wrapper objects are created through factory methods so subclasses can be substituted in the future.');
        add(' * A common interface is implemented by all wrapper classes.');
        add(' * Enums are generated for record types.');
        add(' * An optional filtering mechanism is available that is applied to reads.');
        add(' * Every wrapper can offer an identify value in the form of a syntactically valid but sometimes fake Id.');
        add(' * A "mapified" format of the data - nested Maps using the relationship names - can be generated.');
        add(' */');
        add(classModifier + ' inherited sharing class ' + outerClassName + ' {');

        exceptionClass();
        wrapperInterface();
        filterInterface();
        noFilterClass();
        filterProperty();
        fakeIdGenerator();
        relationshipClass();
        innerClasses();
        mapifyStaticMethod();

        add('}');
    }

    private void exceptionClass() {

        indent++;

        blank();
        add('//');
        add('// For problems');
        add('//');
        add(methodModifier + ' class ' + outerClassName + 'Exception extends Exception {');
        add('}');

        indent--;

    }

    private void wrapperInterface() {

        indent++;

        blank();
        add('//');
        add('// All wrappers implement this');
        add('//');
        add(methodModifier + ' interface Wrapper {');

        indent++;
        blank();
        add('// Return the wrapped SObject');
        add('SObject getSObject();');
        blank();
        add('// Return the wrapped SObject type');
        add('SObjectType getSObjectType();');
        blank();
        add('// Return the identity of the SObject (can be a fake Id value for non-persisted SObjects)');
        add('Id getId();');
        blank();
        add('// Return the record type developer name or null if none');
        add('String getRecordTypeDeveloperName();');
        
        blank();
        add('// Return a specific parent wrapper');
        add('Wrapper getParent(String relationshipName);');
        blank();
        add('// Return a specific array of child wrappers');
        add('Wrapper[] getChildren(String relationshipName);');

        blank();
        add('// Convert to form suitable for returning to external code without globals');
        add('Map<String, Object> mapify(Map<Id, Object> visited);');

        blank();
        add('// Relationship names in both directions');
        add('Relationship[] getParentRelationships();');
        blank();
        add('// Relationship names in both directions');
        add('Relationship[] getChildRelationships();');

        indent--;
        add('}');

        indent--;
    }
    
    private void filterInterface() {

        indent++;

        blank();
        add('//');
        add('// Returned wrappers can have this filter applied');
        add('//');
        add(methodModifier + ' interface Filter {');

        indent++;
        blank();
        add('// Return true if the wrapped object should be returned');
        add('Boolean accept(Wrapper w);');

        indent--;
        add('}');

        indent--;
    }

    private void noFilterClass() {

        indent++;

        blank();
        add('//');
        add('// Filter that returns all objects and a single gamic instance of that filter');
        add('//');
        add('private class NoFilter implements Filter {');

        indent++;
        add(methodModifier + ' Boolean accept(Wrapper w) {');
        indent++;
        add('// All');
        add('return true;');
        indent--;
        add('}');

        indent--;
        add('}');

        add(methodModifier + ' static final Filter NO_FILTER = new NoFilter();');

        indent--;
    }

    private void filterProperty() {

        indent++;

        blank();
        add('//');
        add('// Returned wrappers have this filter applied; intended for readers only');
        add('//');
        add(methodModifier + ' static Filter filter {');

        indent++;
        add('get {');
        indent++;
        add('if (filter == null) filter = NO_FILTER;');
        add('return filter;');
        indent--;
        add('}');
        add('set;');
        indent--;

        add('}');

        indent--;
    }

    private void innerClasses() {

        indent++;

        // Pereserves order from types input field
        for (SObjectType t : sobTypes) {
            Type info = typeInfo.get(t);
            typeComment(info);
            recordTypes(info);
            factoryMethod(info);
            innerClass(info);
        }

        indent--;
    }

    private void typeComment(Type t) {

        blank();
        add('//');
        add('// ' + t.className());
        add('//');
    }

    private void recordTypes(Type t) {
        
        String[] names = t.recordTypeDeveloperNames;
        if (names.size() == 0) return;

        blank();
        add('// Record type enum');
        add(propertyModifier + ' enum ' + t.recordTypeEnumName() + ' {');

        indent++;
        for (Integer i = 0; i < names.size(); i++) add(names[i] + (i < names.size() - 1 ? ',' : ''));
        indent--;

        add('}');

        blank();
        add('// Record type enum lookup');
        add(methodModifier + ' static ' + t.recordTypeEnumName() + ' to' + t.recordTypeEnumName() + '(String developerName) {');

        indent++;
        add('for (' + t.recordTypeEnumName() + ' e : ' + t.recordTypeEnumName() + '.values()) {');
        indent++;
        add('if (e.name() == developerName) return e;');
        indent--;
        add('}');
        add('return null;');
        indent--;

        add('}');
    }

    private void factoryMethod(Type t) {

        blank();
        add('// Factory method');
        add(methodModifier + ' static ' + t.className() + ' ' + t.factoryMethodName() + '(' + t.sobType() + ' sob) {');

        indent++;
        add(t.className() + ' w = new ' + t.className() + '();');
        add('w.sob = sob;');
        add('return w;');
        indent--;

        add('}');
    }

    private void innerClass(Type t) {

        blank();
        add('// Wrapper class');
        add(classModifier + ' class ' + t.className() + ' implements Wrapper {');

        classBody(t);

        add('}');
    }

    private void classBody(Type t) {

        indent++;
        wrappedObject(t);
        transientIdField(t);
        recordTypeFields(t);
        classFields(t);
        classCtor(t);
        wrapperInterfaceMethods(t);
        recordTypeMethod(t);
        classMethods(t);
        indent--;
    }

    private void wrappedObject(Type t) {

        blank();
        add('// Wrapped object');
        add(propertyModifier + ' ' + t.sobType() + ' sob {get; private set;}');
    }

    private void transientIdField(Type t) {

        blank();
        add('// Either the SObject Id or a temporary fake Id');
        add('private Id transientId;');
    }

    private void recordTypeFields(Type t) {

        blank();
        if (t.recordTypeDeveloperNames.size() > 0) {
            add('// Record types known at code generation time');
            add(propertyModifier + ' ' + t.recordTypeEnumName() + ' recordType {get; private set;}');
        }
        add('// Any name');
        add(propertyModifier + ' String recordTypeDeveloperName {get; private set;}');
    }

    private void recordTypeMethod(Type t) {

        blank();
        if (t.recordTypeDeveloperNames.size() > 0) {
            add('// Set the record type starting from the developer name');
            add(methodModifier + ' ' + t.recordTypeEnumName() + ' setRecordType(String developerName) {');
            indent++;
            add('// Any name');
            add('recordTypeDeveloperName = developerName;');
            add('// Enum can be null if record type added after code generation');
            add('recordType = to' + t.recordTypeEnumName() + '(developerName);');
            add('return recordType;');
            indent--;
            add('}');
        } else {
            add('// Any name');
            add(methodModifier + ' String setRecordTypeDeveloperName(String name) {');
            indent++;
            add('recordTypeDeveloperName = name;');
            add('return recordTypeDeveloperName;');
            indent--;
            add('}');
        }
    }

    private void classFields(Type t) {

        Boolean firstParent = true;
        for(Relationship p : t.parents) {
            if (firstParent) {
                blank(); 
                add('// Parent wrapper object relationships');
                firstParent = false;
            }
            String f = p.parentRelationshipName();
            add(propertyModifier + ' ' + p.parentClassName() + ' ' + f + ' {');
            indent++;
            add('get {');
            indent++;
            add('return filter.accept(' + f + ') ? ' + f + ' : null;');
            indent--;
            add('}');
            add('private set;');
            indent--;
            add('}');
        }

        Boolean firstChild = true;
        for(Relationship c : t.children) {
            if (firstChild) {
                blank(); 
                add('// Child wrapper object relationships');
                firstChild = false;
            }
            add(propertyModifier + ' ' + c.childClassName() + '[] ' + c.childRelationshipName() + ' {');
            indent++;
            add('get {');
            indent++;
            add('if (' + c.childRelationshipName() + ' == null) ' + c.childRelationshipName() + ' = new ' + c.childClassName() + '[] {};');
            add('if (filter === NO_FILTER) {');
            indent++;
            add('// Returns the modifiable collection');
            add('return ' + c.childRelationshipName() + ';');
            indent--;
            add('} else {');
            indent++;
            add('// Returns a new collection');
            add(c.childClassName() + '[] ws = new ' + c.childClassName() + '[] {};');
            add('for (' + c.childClassName() + ' w : ' + c.childRelationshipName() + ') {');
            indent++;
            add('if (filter.accept(w)) ws.add(w);');
            indent--;
            add('}');
            add('return ws;');
            indent--;
            add('}');
            indent--;
            add('}');
            add('private set;');
            indent--;
            add('}');
        }
    }

    private void classCtor(Type t) {

        blank();
        add('// Create via factory method only');
        add('private ' + t.className() +  '() {');
        add('}');
    }

    private void classMethods(Type t) {

        Boolean firstParent = true;
        for(Relationship r : t.parents) {
            if (firstParent) {
                blank(); 
                add('// Parent object methods');
                firstParent = false;
            }
            add(methodModifier + ' ' + r.parentClassName() + ' ' + r.parentMethodName() + '(' + r.parentSobType() + ' sob) {');
            parentMethodBody(t, r);
            add('}');
        }

        Boolean firstChild = true;
        for(Relationship r : t.children) {
            if (firstChild) {
                blank(); 
                add('// Child object methods');
                firstChild = false;
            }
            add(methodModifier + ' ' + r.childClassName() + ' ' + r.childMethodName() + '(' + r.childSobType() + ' sob) {');
            childMethodBody(t, r);
            add('}');
        }
    }

    private void wrapperInterfaceMethods(Type t) {

        blank();
        add('// Wrapper interface methods');

        add(methodModifier + ' SObject getSObject() {');
        indent++;
        add('return sob;');
        indent--;
        add('}');

        add(methodModifier + ' SObjectType getSObjectType() {');
        indent++;
        add('return sob.getSObjectType();');
        indent--;
        add('}');

        add(methodModifier + ' Id getId() {');
        indent++;
        add('if (transientId == null) {');
        indent++;
        add('transientId = sob.Id != null ? sob.Id : nextFakeId(' + t.sobType() + '.SObjectType);');
        indent--;
        add('}');
        add('return transientId;');
        indent--;
        add('}');

        add(methodModifier + ' String getRecordTypeDeveloperName() {');
        indent++;
        add('return recordTypeDeveloperName;');
        indent--;
        add('}');

        add(methodModifier + ' Wrapper getParent(String relationshipName) {');
        indent++;
        add('switch on relationshipName {');
        indent++;
        for(Relationship r : t.parents) {
            add('when \'' + r.parentRelationshipName() + '\' { return ' + r.parentRelationshipName() + '; }');
        }
        add('when else { throw new ' + outerClassName + 'Exception(\'Bad parent relationshipName \' + relationshipName); }');
        indent--;
        add('}');
        indent--;
        add('}');

        add(methodModifier + ' Wrapper[] getChildren(String relationshipName) {');
        indent++;
        add('switch on relationshipName {');
        indent++;
        for(Relationship r : t.children) {
            add('when \'' + r.childRelationshipName() + '\' { return ' + r.childRelationshipName() + '; }');
        }
        add('when else { throw new ' + outerClassName + 'Exception(\'Bad children relationshipName \' + relationshipName); }');
        indent--;
        add('}');
        indent--;
        add('}');

        add(methodModifier + ' Relationship[] getParentRelationships() {');
        indent++;
        add('return new Relationship[] {');
        indent++;
        for(Integer i = 0; i < t.parents.size(); i++) {
            Boolean last = i == t.parents.size() - 1;
            Relationship r = t.parents[i];
            add('new Relationship('
                + '\'' + r.parentRelationshipName()
                + '\', \'' + r.rawParentRelationshipName() 
                + '\', \'' + r.childRelationshipName()
                + '\', \'' + r.rawChildRelationshipName()
                + '\''
                + (last ? ')' : '),')
            );
        }
        indent--;
        add('};');
        indent--;
        add('}');

        add(methodModifier + ' Relationship[] getChildRelationships() {');
        indent++;
        add('return new Relationship[] {');
        indent++;
        for(Integer i = 0; i < t.children.size(); i++) {
            Boolean last = i == t.children.size() - 1;
            Relationship r = t.children[i];
            add('new Relationship('
                + '\'' + r.parentRelationshipName()
                + '\', \'' + r.rawParentRelationshipName() 
                + '\', \'' + r.childRelationshipName()
                + '\', \'' + r.rawChildRelationshipName()
                + '\''
                + (last ? ')' : '),')
            );
        }
        indent--;
        add('};');
        indent--;
        add('}');

        add(methodModifier + ' Map<String, Object> mapify(Map<Id, Object> visited) {');
        indent++;
        add('return mapify(this, visited);');
        indent--;
        add('}');
    }

    private void mapifyStaticMethod() {

        indent++;

        blank();
        add('// Wrappers share this code');
        add('private static Map<String, Object> mapify(Wrapper w, Map<Id, Object> visited) {');
        indent++;

        blank();
        add('// Avoid cycles');
        add('if (visited.containsKey(w.getId())) return (Map<String, Object>) visited.get(w.getId());');
        blank();
        add('// A map per SObject');
        add('Map<String, Object> m = new Map<String, Object>();');
        add('visited.put(w.getId(), m);');
        add('m.putAll(w.getSObject().getPopulatedFieldsAsMap());');
        add('m.put(\'Id\', w.getId());');
        blank();
        add('// Rest API style meta data');
        add('Map<String, Object> a = new Map<String, Object>();');
        add('a.put(\'type\', String.valueOf(w.getSObject().getSObjectType()));');
        add('if (w.getRecordTypeDeveloperName() != null) a.put(\'recordType\', w.getRecordTypeDeveloperName());');
        add('m.put(\'attributes\', a);');

        blank();
        add('// Children first');
        add('for (Relationship r : w.getChildRelationships()) {');
        indent++;
        add('List<Map<String, Object>> l = new List<Map<String, Object>>();');
        add('for (Wrapper c : w.getChildren(r.child)) {');
        indent++;
        add('Map<String, object> cMap = c.mapify(visited);');
        add('l.add(cMap);');
        indent--;
        add('}');
        add('// Children reference');
        add('if (l.size() > 0) m.put(r.rawChild, l);');
        indent--;
        add('}');

        blank();
        add('// Parents second');
        add('for (Relationship r : w.getParentRelationships()) {');
        indent++;
        add('Wrapper p = w.getParent(r.parent);');
        add('if (p != null) {');
        indent++;
        add('Map<String, object> pMap = p.mapify(visited);');
        add('// Parent reference');
        add('m.put(r.rawParent, pMap);');
        indent--;
        add('}');
        indent--;
        add('}');

        blank();
        add('return m;');
        indent--;
        add('}');

        indent--;
    }

    private void parentMethodBody(Type t, Relationship r) {

        indent++;
        add(r.parentClassName() + ' w = sob != null ? ' + r.parentFactoryMethodName() + '(sob) : null;');      
        add(r.parentRelationshipName() + ' = w;');
        add('if (w != null) w.' + r.childRelationshipName() + '.add(this);');
        add('return w;');
        indent--;
    }

    private void childMethodBody(Type t, Relationship r) {

        indent++;
        add('if (sob == null) return null;');
        add(r.childClassName() + ' w = ' + r.childFactoryMethodName() + '(sob);');
        add(r.childRelationshipName() + '.add(w);');
        add('w.' + r.parentRelationshipName() + ' = this;');
        add('return w;');
        indent--;
    }

    private void fakeIdGenerator() {

        indent++;
        blank();
        add('//');
        add('// Generate a syntactically valid but fake Id');
        add('//');
        add('private static Integer nextFakeIdInteger = 0;');
        blank();
        add('private static Id nextFakeId(SObjectType t) {');
        indent++;
        blank();
        add('String RESERVED = \'000\';');
        add('String FAKE_TOKEN = \'FAKE\';');
        blank();
        add('String keyPrefix = t.getDescribe().getKeyPrefix();');
        add('String n = String.valueOf(nextFakeIdInteger++);');
        blank();
        add('return keyPrefix + RESERVED + FAKE_TOKEN + \'0\'.repeat(15 - keyPrefix.length() - RESERVED.length() - FAKE_TOKEN.length() - n.length()) + n;');
        indent--;
        add('}');
        indent--;
    }

    private void relationshipClass() {

        indent++;

        blank();
        add('//');
        add('// Relationship names in both directions');
        add('//');
        add(methodModifier + ' class Relationship {');
        indent++;

        blank();
        add('String parent;');
        add('String rawParent;');
        add('String child;');
        add('String rawChild;');
        blank();

        add('Relationship(String parent, String rawParent, String child, String rawChild) {');
        indent++;
        add('this.parent = parent;');
        add('this.rawParent = rawParent;');
        add('this.child = child;');
        add('this.rawChild = rawChild;');
        indent--;
        add('}');

        indent--;
        add('}');

        indent--;
    }

    //
    // Test generation
    //

    private void testClass() {

        add('/*');
        add(' * Generated by the ModelGenerator page - do not edit directly.');
        add(' * ');
        add(' * Cover the generated code.');
        add(' */');
        add('@IsTest(IsParallel=true)');
        add('private class ' + outerClassName + 'Test {');

        testFilter();
        tests();

        add('}');
    }

    private void testFilter() {

        blank();

        indent++;
        add('private class NoneFilter implements ' + q('Filter') + ' {');

        indent++;
        add(methodModifier + ' Boolean accept(' + q('Wrapper') + ' w) {');
        indent++;
        add('// None');
        add('return false;');
        indent--;
        add('}');
        indent--;

        add('}');
        indent--;
    }

    private void tests() {

        indent++;

        // Pereserves order from types input field
        for (SObjectType t : sobTypes) {
            test(typeInfo.get(t));
        }

        indent--;

    }

    private void test(Type t) {

        blank();
        add('@IsTest');
        add('static void ' + t.testName() + '() {');

        indent++;
        testBody(t);
        indent--;

        add('}');
    }

    private void testBody(Type t) {

        blank();
        add('// New');
        add(q(t.className()) + ' w = ' + q(t.factoryMethodName()) + '(new ' + t.sobType() + '());');

        blank();
        add('// Adds');
        for(Relationship p : t.parents) {
            add('System.assertNotEquals(null, w.' + p.parentMethodName() + '(new ' + p.parentSobType() + '()));');
        }
        for(Relationship c : t.children) {
            add('System.assertNotEquals(null, w.' + c.childMethodName() + '(new ' + c.childSobType() + '()));');
        }

        blank();
        if (t.recordTypeDeveloperNames.size() > 0) {
            String first = t.recordTypeDeveloperNames[0];
            String last = t.recordTypeDeveloperNames[t.recordTypeDeveloperNames.size() - 1];
            add('// Enum wrapper method');
            add('System.assertEquals(' + q(t.recordTypeEnumName()) + '.' + first + ', w.setRecordType(\'' + first + '\'));');
            add('// Enum static method');
            add('System.assertEquals(' + q(t.recordTypeEnumName()) + '.' + last + ', ' + q(t.className()) + '.to' + t.recordTypeEnumName() + '(\'' + last + '\'));');
            add('// Non-enum value');
            add('System.assertEquals(null, w.setRecordType(\'Abc123\'));');
            add('System.assertEquals(\'Abc123\', w.recordTypeDeveloperName);');
        } else {
            add('// Any value');
            add('System.assertEquals(\'Abc123\', w.setRecordTypeDeveloperName(\'Abc123\'));');
        }

        blank();
        add('// Wrapper interface methods');
        add('System.assertEquals(w.sob, w.getSObject());');
        add('System.assertEquals(w.getSObject().getSObjectType(), w.getSObjectType());');
        add('System.assertEquals(w.recordTypeDeveloperName, w.getRecordTypeDeveloperName());');
        add('System.assertNotEquals(null, w.getId());');
        add('System.assertEquals(' + t.sobType() + '.SObjectType, w.getId().getSObjectType());');
        add('System.assertNotEquals(null, w.getParentRelationships());');
        add('System.assertNotEquals(null, w.getChildRelationships());');

        blank();
        add('// Unfiltered read');
        for(Relationship p : t.parents) {
            add('System.assertNotEquals(null, w.' + p.parentRelationshipName() + ');');
        }
        for(Relationship c : t.children) {
            add('System.assertEquals(1, w.' + c.childRelationshipName() + '.size());');
        }

        blank();
        add('// Filtered read');
        add(q('filter') + ' = new NoneFilter();');
        for(Relationship p : t.parents) {
            add('System.assertEquals(null, w.' + p.parentRelationshipName() + ');');
        }
        for(Relationship c : t.children) {
            add('System.assertEquals(0, w.' + c.childRelationshipName() + '.size());');
        }
    }

    private String q(String name) {

        return outerClassName + '.' + name;
    }

    private static void addError(String message) {

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
}
