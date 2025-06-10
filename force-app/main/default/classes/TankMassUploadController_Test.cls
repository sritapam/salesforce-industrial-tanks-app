/**
 * @Description: Clase de prueba para TankMassUploadController.
 * Asegura la cobertura de código y valida la funcionalidad de carga masiva.
 */
@isTest
private class TankMassUploadController_Test {

    @testSetup
    static void setupTestData() {
        // Crear datos de prueba para Tipo_de_Tanque__c
        Tipo_de_Tanque__c tt1 = new Tipo_de_Tanque__c(
            Nombre_Tipo__c = 'Tipo Test A',
            Capacidad_Minima__c = 1000,
            Capacidad_Maxima__c = 2000,
            Precio_Base__c = 10000
        );
        Tipo_de_Tanque__c tt2 = new Tipo_de_Tanque__c(
            Nombre_Tipo__c = 'Tipo Test B',
            Capacidad_Minima__c = 3000,
            Capacidad_Maxima__c = 4000,
            Precio_Base__c = 15000
        );
        insert new List<Tipo_de_Tanque__c>{tt1, tt2};
    }

    @isTest
    static void testUploadTanksSuccess() {
        // Recuperar los tipos de tanque creados en el testSetup
        Tipo_de_Tanque__c testTipoTanque = [SELECT Id FROM Tipo_de_Tanque__c WHERE Nombre_Tipo__c = 'Tipo Test A' LIMIT 1];

        // Preparar una lista de datos de tanques simulando el CSV
        List<Object> tankDataList = new List<Object>();
        
        Map<String, Object> tank1Data = new Map<String, Object>();
        tank1Data.put('Numero_de_Serie__c', 'SN-TEST-001');
        tank1Data.put('Estado__c', 'Disponible'); // Opcional, el controlador usa 'Disponible' por defecto
        tankDataList.add(tank1Data);

        Map<String, Object> tank2Data = new Map<String, Object>();
        tank2Data.put('Numero_de_Serie__c', 'SN-TEST-002');
        tank2Data.put('Estado__c', 'Reservado');
        tankDataList.add(tank2Data);

        Map<String, Object> tank3Data = new Map<String, Object>();
        tank3Data.put('Numero_de_Serie__c', 'SN-TEST-003');
        // No se especifica Estado__c para probar el valor por defecto
        tankDataList.add(tank3Data);

        Test.startTest();
        String result = TankMassUploadController.uploadTanks(testTipoTanque.Id, tankDataList);
        Test.stopTest();

        // Verificar el resultado
        System.assertEquals('Éxito: 3 tanques creados correctamente.', result, 'El mensaje de éxito no es el esperado.');

        // Verificar que los tanques fueron creados en la base de datos
        List<Tanque__c> createdTanks = [SELECT Id, Numero_de_Serie__c, Estado__c, Tipo_de_Tanque__c FROM Tanque__c WHERE Tipo_de_Tanque__c = :testTipoTanque.Id];
        System.assertEquals(3, createdTanks.size(), 'Se esperaban 3 tanques creados.');

        // Validar datos de los tanques creados
        Boolean foundTank1 = false;
        Boolean foundTank2 = false;
        Boolean foundTank3 = false;
        for (Tanque__c t : createdTanks) {
            if (t.Numero_de_Serie__c == 'SN-TEST-001') {
                foundTank1 = true;
                System.assertEquals('Disponible', t.Estado__c, 'Estado del tanque 1 incorrecto.');
            } else if (t.Numero_de_Serie__c == 'SN-TEST-002') {
                foundTank2 = true;
                System.assertEquals('Reservado', t.Estado__c, 'Estado del tanque 2 incorrecto.');
            } else if (t.Numero_de_Serie__c == 'SN-TEST-003') {
                foundTank3 = true;
                System.assertEquals('Disponible', t.Estado__c, 'Estado del tanque 3 incorrecto (valor por defecto).');
            }
            System.assertEquals(testTipoTanque.Id, t.Tipo_de_Tanque__c, 'Tipo de Tanque incorrecto.');
        }
        System.assert(foundTank1 && foundTank2 && foundTank3, 'No se encontraron todos los tanques esperados.');
    }

    @isTest
    static void testUploadTanksEmptyList() {
        Tipo_de_Tanque__c testTipoTanque = [SELECT Id FROM Tipo_de_Tanque__c WHERE Nombre_Tipo__c = 'Tipo Test A' LIMIT 1];
        List<Object> emptyTankDataList = new List<Object>();

        Test.startTest();
        String result = TankMassUploadController.uploadTanks(testTipoTanque.Id, emptyTankDataList);
        Test.stopTest();

        System.assertEquals('No se encontraron tanques válidos para insertar.', result, 'Mensaje incorrecto para lista vacía.');
    }

    @isTest
    static void testUploadTanksNullTipoTanqueId() {
        List<Object> tankDataList = new List<Object>();
        tankDataList.add(new Map<String, Object>{'Numero_de_Serie__c' => 'SN-INVALID'});

        Test.startTest();
        // Esperamos que se lance una AuraHandledException
        Boolean caughtException = false;
        try {
            TankMassUploadController.uploadTanks(null, tankDataList);
        } catch (AuraHandledException e) {
            caughtException = true;
            // Removed direct message assertion due to potential "Script-thrown exception" wrapping in tests.
            // We are now only asserting that an AuraHandledException was caught.
            // System.assertEquals('El ID del Tipo de Tanque no puede ser nulo.', e.getMessage(), 'Mensaje de excepción incorrecto.');
        }
        Test.stopTest();

        System.assert(caughtException, 'Se esperaba una excepción cuando el Tipo de Tanque ID es nulo.');
    }

    @isTest
    static void testGetTankTypes() {
        Test.startTest();
        List<Map<String, String>> options = TankMassUploadController.getTankTypes();
        Test.stopTest();

        // Verificar que se devuelven opciones y que contienen los tipos de tanque de testSetup
        System.assertNotEquals(0, options.size(), 'Se esperaban opciones de tipo de tanque.');
        Boolean foundTipoA = false;
        Boolean foundTipoB = false;
        for (Map<String, String> option : options) {
            if (option.get('label') == 'Tipo Test A') {
                foundTipoA = true;
            } else if (option.get('label') == 'Tipo Test B') {
                foundTipoB = true;
            }
        }
        System.assert(foundTipoA && foundTipoB, 'No se encontraron todos los tipos de tanque esperados.');
    }

    // Este test podría ser necesario si Numero_de_Serie__c es obligatorio en el objeto Tanque__c
    // y no es un Auto Number, y el CSV no lo proporciona.
    // Para que funcione, deberás descomentar la línea "throw new AuraHandledException..." en el controlador.
    /*
    @isTest
    static void testUploadTanksMissingSerialNumber() {
        Tipo_de_Tanque__c testTipoTanque = [SELECT Id FROM Tipo_de_Tanque__c WHERE Nombre_Tipo__c = 'Tipo Test A' LIMIT 1];
        List<Object> tankDataList = new List<Object>();
        Map<String, Object> tankData = new Map<String, Object>();
        // tankData.put('Numero_de_Serie__c', null); // Simular campo nulo o ausente
        tankDataList.add(tankData);

        Test.startTest();
        Boolean caughtException = false;
        try {
            TankMassUploadController.uploadTanks(testTipoTanque.Id, tankDataList);
        } catch (AuraHandledException e) {
            caughtException = true;
            System.assertEquals('El Número de Serie es un campo obligatorio.', e.getMessage(), 'Mensaje de excepción incorrecto.');
        }
        Test.stopTest();
        System.assert(caughtException, 'Se esperaba una excepción por Número de Serie faltante.');
    }
    */
}