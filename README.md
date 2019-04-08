# relationship-model-generator

## Introduction

When SObjects are queried in a single query, their parent-child `__r` fields are populated and can be used to navigate from one object to the other. But SOQL doesn't allow a deep tree of objects to be queried in one go, and the collection `__r` fields are immutable.

This Visualforce page code generator produces an inner class per SObject that wraps the SObject and adds fields to model the parent and child relationships. Convenience methods are also included to create the wrappers for parent and child objects and set the relationship fields. A test class is also generated, primarily to ensure the generated code has test coverage.

Use this unchanged or clone and make your own changes. We are not looking for contributions, but rather just sharing some code that might be useful to others.

## Screenshot

[ScreenShot.png]

## Sample code output

```
/*
 * Generated by the RelationshipModelGenerator page - do not edit directly.
 * 
 * Simple type-safe SObject wrapper classes that hold the parent/child relationships
 * to use in place of the __r properties (unusable in general as the collections are immutable).
 * Adding a parent or a child also populates the reverse relationship.
 * The SObject is exposed so its non-relationship fields can be directly accessed.
 * Wrapper objects are created through factory methods so subclasses can be substituted in the future.
 */
public inherited sharing class EligibilityModel {

    // Factory method
    public static Claim newClaim(Claim__c sob) {
        Claim w = new Claim();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class Claim {

        // Wrapped object
        public Claim__c sob {get; private set;}

        // Parent wrapper object relationships
        public AccountWrapper claimantInsuredAccount {get; private set;}
        public ContactWrapper claimantInsured {get; private set;}
        public Claim precedingClaim {get; private set;}

        // Child wrapper object relationships
        public BenefitClaimed[] benefitClaimeds {
            get {
                if (benefitClaimeds == null) benefitClaimeds = new BenefitClaimed[] {};
                return benefitClaimeds;
            }
            private set;
        }
        public ClaimRelationship[] claimRelationships {
            get {
                if (claimRelationships == null) claimRelationships = new ClaimRelationship[] {};
                return claimRelationships;
            }
            private set;
        }
        public Claim[] succeedingClaims {
            get {
                if (succeedingClaims == null) succeedingClaims = new Claim[] {};
                return succeedingClaims;
            }
            private set;
        }

        // Create via factory method only
        private Claim() {
        }

        // Parent object methods
        public AccountWrapper setParentClaimantInsuredAccount(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            claimantInsuredAccount = w;
            w.claims.add(this);
            return w;
        }
        public ContactWrapper setParentClaimantInsured(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            claimantInsured = w;
            w.claims.add(this);
            return w;
        }
        public Claim setParentPrecedingClaim(Claim__c sob) {
            Claim w = newClaim(sob);
            precedingClaim = w;
            w.succeedingClaims.add(this);
            return w;
        }

        // Child object methods
        public BenefitClaimed addChildToBenefitClaimeds(BenefitClaimed__c sob) {
            BenefitClaimed w = newBenefitClaimed(sob);
            benefitClaimeds.add(w);
            w.claim = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationships(ClaimRelationship__c sob) {
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationships.add(w);
            w.claim = this;
            return w;
        }
        public Claim addChildToSucceedingClaims(Claim__c sob) {
            Claim w = newClaim(sob);
            succeedingClaims.add(w);
            w.precedingClaim = this;
            return w;
        }
    }

    // Factory method
    public static BenefitClaimed newBenefitClaimed(BenefitClaimed__c sob) {
        BenefitClaimed w = new BenefitClaimed();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class BenefitClaimed {

        // Wrapped object
        public BenefitClaimed__c sob {get; private set;}

        // Parent wrapper object relationships
        public Claim claim {get; private set;}
        public Benefit benefit {get; private set;}
        public AccountWrapper claimantInsuredAccount {get; private set;}
        public ContactWrapper claimantInsured {get; private set;}

        // Create via factory method only
        private BenefitClaimed() {
        }

        // Parent object methods
        public Claim setParentClaim(Claim__c sob) {
            Claim w = newClaim(sob);
            claim = w;
            w.benefitClaimeds.add(this);
            return w;
        }
        public Benefit setParentBenefit(Benefit__c sob) {
            Benefit w = newBenefit(sob);
            benefit = w;
            w.benefitClaimeds.add(this);
            return w;
        }
        public AccountWrapper setParentClaimantInsuredAccount(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            claimantInsuredAccount = w;
            w.benefitsClaimed.add(this);
            return w;
        }
        public ContactWrapper setParentClaimantInsured(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            claimantInsured = w;
            w.claimantInsuredBenefitsClaimed.add(this);
            return w;
        }
    }

    // Factory method
    public static Benefit newBenefit(Benefit__c sob) {
        Benefit w = new Benefit();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class Benefit {

        // Wrapped object
        public Benefit__c sob {get; private set;}

        // Parent wrapper object relationships
        public Benefit baseBenefit {get; private set;}

        // Child wrapper object relationships
        public BenefitClaimed[] benefitClaimeds {
            get {
                if (benefitClaimeds == null) benefitClaimeds = new BenefitClaimed[] {};
                return benefitClaimeds;
            }
            private set;
        }
        public Benefit[] benefitVariations {
            get {
                if (benefitVariations == null) benefitVariations = new Benefit[] {};
                return benefitVariations;
            }
            private set;
        }

        // Create via factory method only
        private Benefit() {
        }

        // Parent object methods
        public Benefit setParentBaseBenefit(Benefit__c sob) {
            Benefit w = newBenefit(sob);
            baseBenefit = w;
            w.benefitVariations.add(this);
            return w;
        }

        // Child object methods
        public BenefitClaimed addChildToBenefitClaimeds(BenefitClaimed__c sob) {
            BenefitClaimed w = newBenefitClaimed(sob);
            benefitClaimeds.add(w);
            w.benefit = this;
            return w;
        }
        public Benefit addChildToBenefitVariations(Benefit__c sob) {
            Benefit w = newBenefit(sob);
            benefitVariations.add(w);
            w.baseBenefit = this;
            return w;
        }
    }

    // Factory method
    public static ClaimRelationship newClaimRelationship(ClaimRelationship__c sob) {
        ClaimRelationship w = new ClaimRelationship();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class ClaimRelationship {

        // Wrapped object
        public ClaimRelationship__c sob {get; private set;}

        // Parent wrapper object relationships
        public Claim claim {get; private set;}
        public AccountWrapper accountWithAccountLabel {get; private set;}
        public AccountWrapper account {get; private set;}
        public ContactWrapper contactWithContactLabel {get; private set;}
        public ContactWrapper contact {get; private set;}

        // Create via factory method only
        private ClaimRelationship() {
        }

        // Parent object methods
        public Claim setParentClaim(Claim__c sob) {
            Claim w = newClaim(sob);
            claim = w;
            w.claimRelationships.add(this);
            return w;
        }
        public AccountWrapper setParentAccountWithAccountLabel(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            accountWithAccountLabel = w;
            w.claimRelationshipsForAccountLabel.add(this);
            return w;
        }
        public AccountWrapper setParentAccount(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            account = w;
            w.claimRelationships.add(this);
            return w;
        }
        public ContactWrapper setParentContactWithContactLabel(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            contactWithContactLabel = w;
            w.claimRelationshipsForConactLabel.add(this);
            return w;
        }
        public ContactWrapper setParentContact(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            contact = w;
            w.claimRelationships.add(this);
            return w;
        }
    }

    // Factory method
    public static ContactWrapper newContactWrapper(Contact sob) {
        ContactWrapper w = new ContactWrapper();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class ContactWrapper {

        // Wrapped object
        public Contact sob {get; private set;}

        // Parent wrapper object relationships
        public AccountWrapper accountId {get; private set;}
        public ContactWrapper parent {get; private set;}
        public ContactWrapper spouse {get; private set;}

        // Child wrapper object relationships
        public ContactWrapper[] children {
            get {
                if (children == null) children = new ContactWrapper[] {};
                return children;
            }
            private set;
        }
        public ContactWrapper[] spouseChildren {
            get {
                if (spouseChildren == null) spouseChildren = new ContactWrapper[] {};
                return spouseChildren;
            }
            private set;
        }
        public BenefitClaimed[] claimantInsuredBenefitsClaimed {
            get {
                if (claimantInsuredBenefitsClaimed == null) claimantInsuredBenefitsClaimed = new BenefitClaimed[] {};
                return claimantInsuredBenefitsClaimed;
            }
            private set;
        }
        public ClaimRelationship[] claimRelationshipsForConactLabel {
            get {
                if (claimRelationshipsForConactLabel == null) claimRelationshipsForConactLabel = new ClaimRelationship[] {};
                return claimRelationshipsForConactLabel;
            }
            private set;
        }
        public ClaimRelationship[] claimRelationships {
            get {
                if (claimRelationships == null) claimRelationships = new ClaimRelationship[] {};
                return claimRelationships;
            }
            private set;
        }
        public Claim[] claims {
            get {
                if (claims == null) claims = new Claim[] {};
                return claims;
            }
            private set;
        }

        // Create via factory method only
        private ContactWrapper() {
        }

        // Parent object methods
        public AccountWrapper setParentAccountId(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            accountId = w;
            w.contacts.add(this);
            return w;
        }
        public ContactWrapper setParentParent(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            parent = w;
            w.children.add(this);
            return w;
        }
        public ContactWrapper setParentSpouse(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            spouse = w;
            w.spouseChildren.add(this);
            return w;
        }

        // Child object methods
        public ContactWrapper addChildToChildren(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            children.add(w);
            w.parent = this;
            return w;
        }
        public ContactWrapper addChildToSpouseChildren(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            spouseChildren.add(w);
            w.spouse = this;
            return w;
        }
        public BenefitClaimed addChildToClaimantInsuredBenefitsClaimed(BenefitClaimed__c sob) {
            BenefitClaimed w = newBenefitClaimed(sob);
            claimantInsuredBenefitsClaimed.add(w);
            w.claimantInsured = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationshipsForConactLabel(ClaimRelationship__c sob) {
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationshipsForConactLabel.add(w);
            w.contactWithContactLabel = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationships(ClaimRelationship__c sob) {
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationships.add(w);
            w.contact = this;
            return w;
        }
        public Claim addChildToClaims(Claim__c sob) {
            Claim w = newClaim(sob);
            claims.add(w);
            w.claimantInsured = this;
            return w;
        }
    }

    // Factory method
    public static AccountWrapper newAccountWrapper(Account sob) {
        AccountWrapper w = new AccountWrapper();
        w.sob = sob;
        return w;
    }

    // Wrapper class
    public class AccountWrapper {

        // Wrapped object
        public Account sob {get; private set;}

        // Parent wrapper object relationships
        public AccountWrapper parentId {get; private set;}

        // Child wrapper object relationships
        public AccountWrapper[] childAccounts {
            get {
                if (childAccounts == null) childAccounts = new AccountWrapper[] {};
                return childAccounts;
            }
            private set;
        }
        public ContactWrapper[] contacts {
            get {
                if (contacts == null) contacts = new ContactWrapper[] {};
                return contacts;
            }
            private set;
        }
        public BenefitClaimed[] benefitsClaimed {
            get {
                if (benefitsClaimed == null) benefitsClaimed = new BenefitClaimed[] {};
                return benefitsClaimed;
            }
            private set;
        }
        public ClaimRelationship[] claimRelationshipsForAccountLabel {
            get {
                if (claimRelationshipsForAccountLabel == null) claimRelationshipsForAccountLabel = new ClaimRelationship[] {};
                return claimRelationshipsForAccountLabel;
            }
            private set;
        }
        public ClaimRelationship[] claimRelationships {
            get {
                if (claimRelationships == null) claimRelationships = new ClaimRelationship[] {};
                return claimRelationships;
            }
            private set;
        }
        public Claim[] claims {
            get {
                if (claims == null) claims = new Claim[] {};
                return claims;
            }
            private set;
        }

        // Create via factory method only
        private AccountWrapper() {
        }

        // Parent object methods
        public AccountWrapper setParentParentId(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            parentId = w;
            w.childAccounts.add(this);
            return w;
        }

        // Child object methods
        public AccountWrapper addChildToChildAccounts(Account sob) {
            AccountWrapper w = newAccountWrapper(sob);
            childAccounts.add(w);
            w.parentId = this;
            return w;
        }
        public ContactWrapper addChildToContacts(Contact sob) {
            ContactWrapper w = newContactWrapper(sob);
            contacts.add(w);
            w.accountId = this;
            return w;
        }
        public BenefitClaimed addChildToBenefitsClaimed(BenefitClaimed__c sob) {
            BenefitClaimed w = newBenefitClaimed(sob);
            benefitsClaimed.add(w);
            w.claimantInsuredAccount = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationshipsForAccountLabel(ClaimRelationship__c sob) {
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationshipsForAccountLabel.add(w);
            w.accountWithAccountLabel = this;
            return w;
        }
        public ClaimRelationship addChildToClaimRelationships(ClaimRelationship__c sob) {
            ClaimRelationship w = newClaimRelationship(sob);
            claimRelationships.add(w);
            w.account = this;
            return w;
        }
        public Claim addChildToClaims(Claim__c sob) {
            Claim w = newClaim(sob);
            claims.add(w);
            w.claimantInsuredAccount = this;
            return w;
        }
    }
}
```
## Sample test output
```
/*
 * Generated by the RelationshipModelGenerator page - do not edit directly.
 * 
 * Cover the generated code.
 */
@IsTest
private class EligibilityModelTest {

    @IsTest
    static void claim() {
        EligibilityModel.Claim w = EligibilityModel.newClaim(new Claim__c());
        System.assertNotEquals(null, w.setParentClaimantInsuredAccount(new Account()));
        System.assertNotEquals(null, w.setParentClaimantInsured(new Contact()));
        System.assertNotEquals(null, w.setParentPrecedingClaim(new Claim__c()));
        System.assertNotEquals(null, w.addChildToBenefitClaimeds(new BenefitClaimed__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationships(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToSucceedingClaims(new Claim__c()));
    }

    @IsTest
    static void benefitClaimed() {
        EligibilityModel.BenefitClaimed w = EligibilityModel.newBenefitClaimed(new BenefitClaimed__c());
        System.assertNotEquals(null, w.setParentClaim(new Claim__c()));
        System.assertNotEquals(null, w.setParentBenefit(new Benefit__c()));
        System.assertNotEquals(null, w.setParentClaimantInsuredAccount(new Account()));
        System.assertNotEquals(null, w.setParentClaimantInsured(new Contact()));
    }

    @IsTest
    static void benefit() {
        EligibilityModel.Benefit w = EligibilityModel.newBenefit(new Benefit__c());
        System.assertNotEquals(null, w.setParentBaseBenefit(new Benefit__c()));
        System.assertNotEquals(null, w.addChildToBenefitClaimeds(new BenefitClaimed__c()));
        System.assertNotEquals(null, w.addChildToBenefitVariations(new Benefit__c()));
    }

    @IsTest
    static void claimRelationship() {
        EligibilityModel.ClaimRelationship w = EligibilityModel.newClaimRelationship(new ClaimRelationship__c());
        System.assertNotEquals(null, w.setParentClaim(new Claim__c()));
        System.assertNotEquals(null, w.setParentAccountWithAccountLabel(new Account()));
        System.assertNotEquals(null, w.setParentAccount(new Account()));
        System.assertNotEquals(null, w.setParentContactWithContactLabel(new Contact()));
        System.assertNotEquals(null, w.setParentContact(new Contact()));
    }

    @IsTest
    static void contactWrapper() {
        EligibilityModel.ContactWrapper w = EligibilityModel.newContactWrapper(new Contact());
        System.assertNotEquals(null, w.setParentAccountId(new Account()));
        System.assertNotEquals(null, w.setParentParent(new Contact()));
        System.assertNotEquals(null, w.setParentSpouse(new Contact()));
        System.assertNotEquals(null, w.addChildToChildren(new Contact()));
        System.assertNotEquals(null, w.addChildToSpouseChildren(new Contact()));
        System.assertNotEquals(null, w.addChildToClaimantInsuredBenefitsClaimed(new BenefitClaimed__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationshipsForConactLabel(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationships(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToClaims(new Claim__c()));
    }

    @IsTest
    static void accountWrapper() {
        EligibilityModel.AccountWrapper w = EligibilityModel.newAccountWrapper(new Account());
        System.assertNotEquals(null, w.setParentParentId(new Account()));
        System.assertNotEquals(null, w.addChildToChildAccounts(new Account()));
        System.assertNotEquals(null, w.addChildToContacts(new Contact()));
        System.assertNotEquals(null, w.addChildToBenefitsClaimed(new BenefitClaimed__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationshipsForAccountLabel(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToClaimRelationships(new ClaimRelationship__c()));
        System.assertNotEquals(null, w.addChildToClaims(new Claim__c()));
    }
}
```
