# relationship-model-generator

## Introduction

When SObjects are queried in a single query, their parent-child `__r` fields are populated and can be used to navigate from one object to the other. But SOQL doesn't allow a deep tree of objects to be queried in one go, and the collection `__r` fields are immutable.

This Visualforce page code generator produces an inner class per SObject that wraps the SObject and adds fields to model the parent and child relationships. Apex `enum`s are created for the Record Types. Convenience methods are included to connect up parent or child objects and ensure that the relationship fields are set. A filtering mechanism is available for reads. Where an `Id` isn't already known, a valid fake `Id` is generated so map logic keyed by `Id` can be used. Generic methods are provided so the relationships can be accessed by name, and the parent/child relationship names are also provided. A pure map form of the model - the **mapified** form - can be output for code that cannot be coupled to the model classes. A test class is also generated, primarily to ensure the generated code has test coverage.

Use this unchanged or clone and make your own changes. The code is generic - there are just a few default values tied to our specific objects. We are not looking for contributions, but rather just sharing some code that may be useful to others.

## Screenshot

![Screenshot](ScreenShot.png)

## Sample code output

This is the first part of some code generated by this page that illustrates the resulting patterns:

```
/*
 * Generated by the ModelGenerator page - do not edit directly.
 * 
 * Simple type-safe SObject wrapper classes that hold the parent/child relationships
 * to use in place of the __r properties (unusable in general as the collections are immutable).
 * Adding a parent or a child also populates the reverse relationship.
 * The SObject is exposed so its non-relationship fields can be directly accessed.
 * Wrapper objects are created through factory methods so subclasses can be substituted in the future.
 * A common interface is implemented by all wrapper classes.
 * Enums are generated for record types.
 * An optional filtering mechanism is available that is applied to reads.
 * Every wrapper can offer an identify value in the form of a syntactically valid but sometimes fake Id.
 * A "mapified" format of the data - nested Maps using the relationship names - can be generated.
 */
public inherited sharing class EligibilityModel {

    //
    // For problems
    //
    public class EligibilityModelException extends Exception {
    }

    //
    // All wrappers implement this
    //
    public interface Wrapper {

        // Return the wrapped SObject
        SObject getSObject();

        // Return the wrapped SObject type
        SObjectType getSObjectType();

        // Return the identity of the SObject (can be a fake Id value for non-persisted SObjects)
        Id getId();

        // Return the record type developer name or null if none
        String getRecordTypeDeveloperName();

        // Return a specific parent wrapper
        Wrapper getParent(String relationshipName);

        // Return a specific array of child wrappers
        Wrapper[] getChildren(String relationshipName);

        // Convert to form suitable for returning to external code without globals
        Map<String, Object> mapify(Map<Id, Object> visited);

        // Relationship names in both directions
        Relationship[] getParentRelationships();

        // Relationship names in both directions
        Relationship[] getChildRelationships();
    }

    //
    // Returned wrappers can have this filter applied
    //
    public interface Filter {

        // Return true if the wrapped object should be returned
        Boolean accept(Wrapper w);
    }

    //
    // Filter that returns all objects and a single gamic instance of that filter
    //
    private class NoFilter implements Filter {
        public Boolean accept(Wrapper w) {
            // All
            return true;
        }
    }
    public static final Filter NO_FILTER = new NoFilter();

    //
    // Returned wrappers have this filter applied; intended for readers only
    //
    public static Filter filter {
        get {
            if (filter == null) filter = NO_FILTER;
            return filter;
        }
        set;
    }

    //
    // Generate a syntactically valid but fake Id
    //
    private static Integer nextFakeIdInteger = 0;

    private static Id nextFakeId(SObjectType t) {

        String RESERVED = '000';
        String FAKE_TOKEN = 'FAKE';

        String keyPrefix = t.getDescribe().getKeyPrefix();
        String n = String.valueOf(nextFakeIdInteger++);

        return keyPrefix + RESERVED + FAKE_TOKEN + '0'.repeat(15 - keyPrefix.length() - RESERVED.length() - FAKE_TOKEN.length() - n.length()) + n;
    }

    //
    // Relationship names in both directions
    //
    public class Relationship {

        String parent;
        String rawParent;
        String child;
        String rawChild;

        Relationship(String parent, String rawParent, String child, String rawChild) {
            this.parent = parent;
            this.rawParent = rawParent;
            this.child = child;
            this.rawChild = rawChild;
        }
    }

    //
    // Claim
    //

    // Factory method
    public static Claim newClaim(Claim__c sob) {
        Claim w = new Claim();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class Claim implements Wrapper {

        // Wrapped object
        public Claim__c sob {get; private set;}

        // Either the SObject Id or a temporary fake Id
        private Id transientId;

        // Any name
        public String recordTypeDeveloperName {get; private set;}

        // Parent wrapper object relationships
        public ContactWrapper claimantInsured {
            get {
                return filter.accept(claimantInsured) ? claimantInsured : null;
            }
            private set;
        }
        public Policy policy {
            get {
                return filter.accept(policy) ? policy : null;
            }
            private set;
        }

        // Child wrapper object relationships
        public BenefitClaimed[] benefitClaimeds {
            get {
                if (benefitClaimeds == null) benefitClaimeds = new BenefitClaimed[] {};
                if (filter === NO_FILTER) {
                    // Returns the modifiable collection
                    return benefitClaimeds;
                } else {
                    // Returns a new collection
                    BenefitClaimed[] ws = new BenefitClaimed[] {};
                    for (BenefitClaimed w : benefitClaimeds) {
                        if (filter.accept(w)) ws.add(w);
                    }
                    return ws;
                }
            }
            private set;
        }
        public ClaimRelationship[] claimRelationships {
            get {
                if (claimRelationships == null) claimRelationships = new ClaimRelationship[] {};
                if (filter === NO_FILTER) {
                    // Returns the modifiable collection
                    return claimRelationships;
                } else {
                    // Returns a new collection
                    ClaimRelationship[] ws = new ClaimRelationship[] {};
                    for (ClaimRelationship w : claimRelationships) {
                        if (filter.accept(w)) ws.add(w);
                    }
                    return ws;
                }
            }
            private set;
        }
        public Journal[] journals {
            get {
                if (journals == null) journals = new Journal[] {};
                if (filter === NO_FILTER) {
                    // Returns the modifiable collection
                    return journals;
                } else {
                    // Returns a new collection
                    Journal[] ws = new Journal[] {};
                    for (Journal w : journals) {
                        if (filter.accept(w)) ws.add(w);
                    }
                    return ws;
                }
            }
            private set;
        }
        public PaymentSpecification[] paymentSpecifications {
            get {
                if (paymentSpecifications == null) paymentSpecifications = new PaymentSpecification[] {};
                if (filter === NO_FILTER) {
                    // Returns the modifiable collection
                    return paymentSpecifications;
                } else {
                    // Returns a new collection
                    PaymentSpecification[] ws = new PaymentSpecification[] {};
                    for (PaymentSpecification w : paymentSpecifications) {
                        if (filter.accept(w)) ws.add(w);
                    }
                    return ws;
                }
            }
            private set;
        }

        // Create via factory method only
        private Claim() {
        }

        // Wrapper interface methods
        public SObject getSObject() {
            return sob;
        }
        public SObjectType getSObjectType() {
            return sob.getSObjectType();
        }
        public Id getId() {
            if (transientId == null) {
                transientId = sob.Id != null ? sob.Id : nextFakeId(Claim__c.SObjectType);
            }
            return transientId;
        }
        public String getRecordTypeDeveloperName() {
            return recordTypeDeveloperName;
        }
        public Wrapper getParent(String relationshipName) {
            switch on relationshipName {
                when 'claimantInsured' { return claimantInsured; }
                when 'policy' { return policy; }
                when else { throw new EligibilityModelException('Bad parent relationshipName ' + relationshipName); }
            }
        }
        public Wrapper[] getChildren(String relationshipName) {
            switch on relationshipName {
                when 'benefitClaimeds' { return benefitClaimeds; }
                when 'claimRelationships' { return claimRelationships; }
                when 'journals' { return journals; }
                when 'paymentSpecifications' { return paymentSpecifications; }
                when else { throw new EligibilityModelException('Bad children relationshipName ' + relationshipName); }
            }
        }
        public Relationship[] getParentRelationships() {
            return new Relationship[] {
                new Relationship('claimantInsured', 'cve__ClaimantInsured__r', 'claims', 'cve__Claims__r'),
                new Relationship('policy', 'cve__Policy__r', 'claims', 'cve__Claims__r')
            };
        }
        public Relationship[] getChildRelationships() {
            return new Relationship[] {
                new Relationship('claim', 'cve__Claim__r', 'benefitClaimeds', 'cve__BenefitClaimeds__r'),
                new Relationship('claim', 'cve__Claim__r', 'claimRelationships', 'cve__ClaimRelationships__r'),
                new Relationship('claim', 'cve__Claim__r', 'journals', 'cve__Journals__r'),
                new Relationship('claim', 'cve__Claim__r', 'paymentSpecifications', 'cve__PaymentSpecifications__r')
            };
        }
        public Map<String, Object> mapify(Map<Id, Object> visited) {
            return mapify(this, visited);
        }

        // Any name
        public String setRecordTypeDeveloperName(String name) {
            recordTypeDeveloperName = name;
            return recordTypeDeveloperName;
        }

        // Parent object methods
        public ContactWrapper setParentClaimantInsured(Contact sob) {
            ContactWrapper w = sob != null ? newContactWrapper(sob) : null;
            claimantInsured = w;
            if (w != null) w.claims.add(this);
            return w;
        }
        public Policy setParentPolicy(Policy__c sob) {
            Policy w = sob != null ? newPolicy(sob) : null;
            policy = w;
            if (w != null) w.claims.add(this);
            return w;
        }

        // Child object methods
        public BenefitClaimed addChildToBenefitClaimeds(BenefitClaimed__c sob) {
            if (sob == null) return null;
            BenefitClaimed w = newBenefitClaimed(sob);
            benefitClaimeds.add(w);
            w.claim = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationships(ClaimRelationship__c sob) {
            if (sob == null) return null;
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationships.add(w);
            w.claim = this;
            return w;
        }
        public Journal addChildToJournals(Journal__c sob) {
            if (sob == null) return null;
            Journal w = newJournal(sob);
            journals.add(w);
            w.claim = this;
            return w;
        }
        public PaymentSpecification addChildToPaymentSpecifications(PaymentSpecification__c sob) {
            if (sob == null) return null;
            PaymentSpecification w = newPaymentSpecification(sob);
            paymentSpecifications.add(w);
            w.claim = this;
            return w;
        }
    }
    
    ...
```
## Sample test output
```
/*
 * Generated by the ModelGenerator page - do not edit directly.
 * 
 * Cover the generated code.
 */
@IsTest
private class EligibilityModelTest {

    @IsTest
    static void claim() {

        EligibilityModel.Claim w = EligibilityModel.newClaim(new Claim__c());
        System.assertNotEquals(null, w.setParentClaimantInsured(new Contact()));
        System.assertNotEquals(null, w.setParentPolicy(new Policy__c()));
        System.assertNotEquals(null, w.addChildToBenefitClaimeds(new BenefitClaimed__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationships(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToJournals(new Journal__c()));
        System.assertNotEquals(null, w.addChildToPaymentSpecifications(new PaymentSpecification__c()));

        // Any value
        System.assertEquals('Abc123', w.setRecordTypeDeveloperName('Abc123'));
    }

    @IsTest
    static void benefitClaimed() {

        EligibilityModel.BenefitClaimed w = EligibilityModel.newBenefitClaimed(new BenefitClaimed__c());
        System.assertNotEquals(null, w.setParentClaim(new Claim__c()));
        System.assertNotEquals(null, w.setParentBenefit(new Benefit__c()));
        System.assertNotEquals(null, w.setParentLatestJournal(new Journal__c()));
        System.assertNotEquals(null, w.setParentLatestPaymentSpecification(new PaymentSpecification__c()));
        System.assertNotEquals(null, w.setParentPolicy(new Policy__c()));
        System.assertNotEquals(null, w.addChildToCoveragesClaimed(new CoverageClaimed__c()));
        System.assertNotEquals(null, w.addChildToJournals(new Journal__c()));
        System.assertNotEquals(null, w.addChildToPaymentSpecifications(new PaymentSpecification__c()));

        // Enum wrapper method
        System.assertEquals(EligibilityModel.BenefitClaimedRecordType.Accident, w.setRecordType('Accident'));
        // Enum static method
        System.assertEquals(EligibilityModel.BenefitClaimedRecordType.WholeLife, EligibilityModel.BenefitClaimed.toBenefitClaimedRecordType('WholeLife'));
        // Non-enum value
        System.assertEquals(null, w.setRecordType('Abc123'));
        System.assertEquals('Abc123', w.recordTypeDeveloperName);
    }
    
    ...
```
