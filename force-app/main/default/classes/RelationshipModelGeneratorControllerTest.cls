@IsTest
private class RelationshipModelGeneratorControllerTest {

    @IsTest
    static void test() {
        RelationshipModelGeneratorController c = new RelationshipModelGeneratorController();
        c.generate();
        System.assertNotEquals(null, c.code);
        System.assertNotEquals(null, c.test);
    }
}
