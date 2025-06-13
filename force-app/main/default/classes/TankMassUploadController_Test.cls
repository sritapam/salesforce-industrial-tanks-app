/**
 * @Description: Clase de prueba para TankMassUploadController.
 * Asegura la cobertura de código y valida la funcionalidad de carga masiva.
 */
@isTest
private class TankMassUploadController_Test {

    // Variable para almacenar el ID del Tipo_de_Tanque__c del testSetup
    private static Id tipoTanqueAIdFromSetup; 

    @testSetup
    static void setupTestData() {
        // Crear datos de prueba para Tipo_de_Tanque__c
        // Asegurarse de poblar todos los campos obligatorios para Tipo_de_Tanque__c
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

        // Asignar el ID directamente desde el objeto insertado, no con una nueva consulta.
        tipoTanqueAIdFromSetup = tt1.Id; 
    }

    @isTest
    static void testUploadTanksSuccess() {
        Id testTipoTanqueId;

        Test.startTest();
        Tipo_de_Tanque__c queriedTt = [SELECT Id FROM Tipo_de_Tanque__c WHERE Nombre_Tipo__c = 'Tipo Test A' LIMIT 1];
        testTipoTanqueId = queriedTt.Id;

        String uniqueSuffix = System.currentTimeMillis() + '-' + String.valueOf(Crypto.getRandomInteger()); 

        List<Object> tankDataList = new List<Object>();
        
        Map<String, Object> tank1Data = new Map<String, Object>();
        tank1Data.put('Numero_de_Serie__c', 'SN-TEST-001-' + uniqueSuffix); 
        tank1Data.put('Estado__c', 'Disponible');
        // No se incluyen Capacidad_OLD__c ni Precio_OLD__c para probar que se asignan los valores por defecto
        tankDataList.add(tank1Data);

        Map<String, Object> tank2Data = new Map<String, Object>(); 
        tank2Data.put('Numero_de_Serie__c', 'SN-TEST-002-' + uniqueSuffix); 
        tank2Data.put('Estado__c', 'Reservado');
        tankDataList.add(tank2Data);

        Map<String, Object> tank3Data = new Map<String, Object>(); 
        tank3Data.put('Numero_de_Serie__c', 'SN-TEST-003-' + uniqueSuffix); 
        tankDataList.add(tank3Data);

        String result = TankMassUploadController.uploadTanks(testTipoTanqueId, tankDataList);
        Test.stopTest();

        System.assertEquals('Éxito: 3 tanques creados correctamente.', result, 'El mensaje de éxito no es el esperado.');

        List<Tanque__c> createdTanks = [SELECT Id, Numero_de_Serie__c, Estado__c, Tipo_de_Tanque__c, Capacidad_OLD__c, Precio_OLD__c FROM Tanque__c WHERE Tipo_de_Tanque__c = :testTipoTanqueId];
        System.assertEquals(3, createdTanks.size(), 'Se esperaban 3 tanques creados.');

        Boolean foundTank1 = false;
        Boolean foundTank2 = false;
        Boolean foundTank3 = false;
        for (Tanque__c t : createdTanks) {
            if (t.Numero_de_Serie__c == 'SN-TEST-001-' + uniqueSuffix) {
                foundTank1 = true;
                System.assertEquals(1, t.Capacidad_OLD__c, 'Capacidad por defecto del tanque 1 incorrecta.'); // Se espera el valor por defecto
                System.assertEquals(0.01, t.Precio_OLD__c, 'Precio por defecto del tanque 1 incorrecto.');     // Se espera el valor por defecto
            } else if (t.Numero_de_Serie__c == 'SN-TEST-002-' + uniqueSuffix) {
                foundTank2 = true;
                System.assertEquals(1, t.Capacidad_OLD__c, 'Capacidad por defecto del tanque 2 incorrecta.');
                System.assertEquals(0.01, t.Precio_OLD__c, 'Precio por defecto del tanque 2 incorrecto.');
            } else if (t.Numero_de_Serie__c == 'SN-TEST-003-' + uniqueSuffix) {
                foundTank3 = true;
                System.assertEquals('Disponible', t.Estado__c, 'Estado del tanque 3 incorrecto (valor por defecto).');
                System.assertEquals(1, t.Capacidad_OLD__c, 'Capacidad por defecto del tanque 3 incorrecta.');
                System.assertEquals(0.01, t.Precio_OLD__c, 'Precio por defecto del tanque 3 incorrecto.');
            }
            
            System.assertEquals(testTipoTanqueId, t.Tipo_de_Tanque__c, 'Tipo de Tanque incorrecto.');
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
        tankDataList.add(new Map<String, Object>{'Numero_de_Serie__c' => 'SN-INVALID'}); // No se requiere Capacidad/Precio OLD aquí para este test

        Test.startTest();
        Boolean caughtException = false;
        try {
            TankMassUploadController.uploadTanks(null, tankDataList);
        } catch (AuraHandledException e) {
            caughtException = true;
        }
        Test.stopTest();

        System.assert(caughtException, 'Se esperaba una excepción cuando el Tipo de Tanque ID es nulo.');
    }

    @isTest
    static void testGetTankTypes() {
        Test.startTest();
        List<Map<String, String>> options = TankMassUploadController.getTankTypes();
        Test.stopTest();

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

    @isTest
    static void testUploadTanksTipoTanqueNotFound() {
        Tipo_de_Tanque__c dummyTt = new Tipo_de_Tanque__c(
            Nombre_Tipo__c = 'Dummy Test ' + System.currentTimeMillis(),
            Capacidad_Minima__c = 1, Capacidad_Maxima__c = 2, Precio_Base__c = 1
        );
        insert dummyTt;
        Id nonExistentTipoTanqueId = dummyTt.Id;
        delete dummyTt; 

        List<Object> tankDataList = new List<Object>();
        tankDataList.add(new Map<String, Object>{'Numero_de_Serie__c' => 'SN-NONEXISTENT'}); // No se requiere Capacidad/Precio OLD aquí para este test

        Test.startTest();
        Boolean caughtException = false;
        try {
            TankMassUploadController.uploadTanks(nonExistentTipoTanqueId, tankDataList);
        } catch (AuraHandledException e) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(caughtException, 'Se esperaba una excepción cuando el Tipo de Tanque no existe.');
    }

    @isTest
    static void testUploadTanksTipoTanqueMissingSerialNumberInCSV() {
        String uniqueSuffix = System.currentTimeMillis() + '-' + String.valueOf(Crypto.getRandomInteger()); 
        
        List<Object> tankDataList = new List<Object>();
        Map<String, Object> tankData = new Map<String, Object>();
        // No se pone Numero_de_Serie__c a propósito
        tankData.put('Estado__c', 'Disponible');
        // Capacidad_OLD__c y Precio_OLD__c no se necesitan aquí ya que no son obligatorios en el controlador
        tankDataList.add(tankData);

        Test.startTest();
        Boolean caughtException = false;
        try {
            TankMassUploadController.uploadTanks(tipoTanqueAIdFromSetup, tankDataList); 
        } catch (AuraHandledException e) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(caughtException, 'Se esperaba una excepción por Número de Serie faltante.');
    }
}