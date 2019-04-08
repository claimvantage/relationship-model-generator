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

    // Per SObject
    private class Type {

        RelationshipModelGeneratorController controller;
        SObjectType sobType;
        Relationship[] parents = new Relationship[] {};
        Relationship[] children = new Relationship[] {};

        Type(RelationshipModelGeneratorController controller, SObjectType sobType) {
            this.controller = controller;
            this.sobType = sobType;
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

        String childRelationshipName() {
            return stripRelationshipName(relationshipName).uncapitalize() + (deduplicate ? 'Children' : '');
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
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Did not recognise SObjectType ' + type + ' so no code generated for that'));
                    }
                }
            }
            return sobTypes;
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
                        if (sobTypes.contains(ct) && c.getRelationshipName() != null) {
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

    // UI form fields
    public String types {get; set;}
    public String outerClassName {get; set;}
    public String namespacePrefixToStrip {get; set;}
    public String code {get; set;}
    public String test {get; set;}

    public RelationshipModelGeneratorController() {

        types = String.join(DEFAULT_TYPES, '\n');
        outerClassName = 'EligibilityModel';
        namespacePrefixToStrip = 'cve__';
    }

    public PageReference generate() {

        lines.clear();
        outerClass();
        code = String.join(lines, '\n');

        lines.clear();
        testClass();
        test = String.join(lines, '\n');

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
    // Code
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
        add(' */');
        add('public inherited sharing class ' + outerClassName + ' {');

        innerClasses();

        add('}');
    }

    private void innerClasses() {

        indent++;

        // Pereserves order from types input field
        for (SObjectType t : sobTypes) {
            factoryMethod(typeInfo.get(t));
            innerClass(typeInfo.get(t));
        }

        indent--;
    }

    private void factoryMethod(Type t) {

        blank();
        add('// Factory method');
        add('public static ' + t.className() + ' ' + t.factoryMethodName() + '(' + t.sobType() + ' sob) {');

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
        add('public class ' + t.className() + ' {');

        classBody(t);

        add('}');
    }

    private void classBody(Type t) {

        indent++;
        wrappedObject(t);
        classFields(t);
        classCtor(t);
        classMethods(t);
        indent--;
    }

    private void wrappedObject(Type t) {

        blank();
        add('// Wrapped object');
        add('public ' + t.sobType() + ' sob {get; private set;}');
    }

    private void classFields(Type t) {

        Boolean firstParent = true;
        for(Relationship p : t.parents) {
            if (firstParent) {
                blank(); 
                add('// Parent wrapper object relationships');
                firstParent = false;
            }
            add('public ' + p.parentClassName() + ' ' + p.parentRelationshipName() + ' {get; private set;}');
        }

        Boolean firstChild = true;
        for(Relationship c : t.children) {
            if (firstChild) {
                blank(); 
                add('// Child wrapper object relationships');
                firstChild = false;
            }
            add('public ' + c.childClassName() + '[] ' + c.childRelationshipName() + ' {');
            indent++;
            add('get {');
            indent++;
            add('if (' + c.childRelationshipName() + ' == null) ' + c.childRelationshipName() + ' = new ' + c.childClassName() + '[] {};');
            add('return ' + c.childRelationshipName() + ';');
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
            add('public ' + r.parentClassName() + ' ' + r.parentMethodName() + '(' + r.parentSobType() + ' sob) {');
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
            add('public ' + r.childClassName() + ' ' + r.childMethodName() + '(' + r.childSobType() + ' sob) {');
            childMethodBody(t, r);
            add('}');
        }
    }

    private void parentMethodBody(Type t, Relationship r) {

        indent++;
        add(r.parentClassName() + ' w = ' + r.parentFactoryMethodName() + '(sob);');      
        add(r.parentRelationshipName() + ' = w;');
        add('w.' + r.childRelationshipName() + '.add(this);');
        add('return w;');
        indent--;
    }

    private void childMethodBody(Type t, Relationship r) {

        indent++;
        add(r.childClassName() + ' w = ' + r.childFactoryMethodName() + '(sob);');
        add(r.childRelationshipName() + '.add(w);');
        add('w.' + r.parentRelationshipName() + ' = this;');
        add('return w;');
        indent--;
    }

    //
    // Test
    //

    private void testClass() {

        add('/*');
        add(' * Generated by the ModelGenerator page - do not edit directly.');
        add(' * ');
        add(' * Cover the generated code.');
        add(' */');
        add('@IsTest');
        add('private class ' + outerClassName + 'Test {');

        tests();

        add('}');
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

        add(q(t.className()) + ' w = ' + q(t.factoryMethodName()) + '(new ' + t.sobType() + '());');
        for(Relationship p : t.parents) {
            add('System.assertNotEquals(null, w.' + p.parentMethodName() + '(new ' + p.parentSobType() + '()));');
        }
        for(Relationship c : t.children) {
            add('System.assertNotEquals(null, w.' + c.childMethodName() + '(new ' + c.childSobType() + '()));');
        }
    }

    private String q(String name) {

        return outerClassName + '.' + name;
    }
}