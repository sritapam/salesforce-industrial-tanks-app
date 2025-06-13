/**
 * @Description: Controlador Apex para la carga masiva de registros de Tanque__c.
 * Permite insertar múltiples registros de Tanque__c desde un LWC,
 * asociándolos a un Tipo_de_Tanque__c específico.
 */
public with sharing class TankMassUploadController {

    /**
     * @Description: Método invocable desde LWC para insertar masivamente tanques.
     * @param tipoTanqueId El ID del Tipo_de_Tanque__c al que se asociarán todos los tanques.
     * @param tankDataList Una lista de mapas, donde cada mapa representa los datos de un tanque
     * (esperando Numero_de_Serie__c y opcionalmente Estado__c, Capacidad_OLD__c y Precio_OLD__c).
     * @return String Un mensaje de éxito o error.
     */
    @AuraEnabled
    public static String uploadTanks(Id tipoTanqueId, List<Object> tankDataList) {
        // Validar si el tipo de tanque es nulo
        if (tipoTanqueId == null) {
            throw new AuraHandledException('El ID del Tipo de Tanque no puede ser nulo.');
        }

        // Obtener los detalles del Tipo_de_Tanque__c (solo necesitamos el Id para la asignación)
        Tipo_de_Tanque__c tipoTanque;
        try {
            tipoTanque = [SELECT Id FROM Tipo_de_Tanque__c WHERE Id = :tipoTanqueId LIMIT 1];
        } catch (QueryException e) {
            System.debug('QueryException al buscar Tipo de Tanque: ' + e.getMessage());
            throw new AuraHandledException('No se encontró el Tipo de Tanque con el ID proporcionado: ' + tipoTanqueId);
        }
        
        List<Tanque__c> tanksToInsert = new List<Tanque__c>();

        for (Object tankDataObj : tankDataList) {
            Map<String, Object> tankData = (Map<String, Object>)tankDataObj;

            Tanque__c newTank = new Tanque__c();

            // Asociar el Tipo_de_Tanque__c al nuevo tanque
            newTank.Tipo_de_Tanque__c = tipoTanqueId;

            // Mapear el Número de Serie desde los datos del CSV (obligatorio)
            if (tankData.containsKey('Numero_de_Serie__c') && tankData.get('Numero_de_Serie__c') != null) {
                newTank.Numero_de_Serie__c = String.valueOf(tankData.get('Numero_de_Serie__c'));
            } else {
                System.debug('Advertencia: Numero_de_Serie__c no encontrado o nulo para un registro de tanque en la carga masiva.');
                throw new AuraHandledException('El campo Numero_de_Serie__c es obligatorio y no se encontró en los datos del CSV.');
            }

            // Mapear el Estado__c (opcional, por defecto 'Disponible')
            if (tankData.containsKey('Estado__c') && tankData.get('Estado__c') != null) {
                newTank.Estado__c = String.valueOf(tankData.get('Estado__c'));
            } else {
                newTank.Estado__c = 'Disponible';
            }

            // Mapear Capacidad_OLD__c del CSV o asignar un valor por defecto
            if (tankData.containsKey('Capacidad_OLD__c') && tankData.get('Capacidad_OLD__c') != null) {
                // Se asegura que el valor sea String antes de la conversión a Decimal
                newTank.Capacidad_OLD__c = Decimal.valueOf(String.valueOf(tankData.get('Capacidad_OLD__c')));
            } else {
                // ASIGNAR VALOR POR DEFECTO para que la inserción no falle por campo obligatorio.
                newTank.Capacidad_OLD__c = 1; // Un valor mínimo para satisfacer la obligatoriedad.
                System.debug('Capacidad_OLD__c no encontrada en CSV, asignando valor por defecto: ' + newTank.Capacidad_OLD__c);
            }

            // Mapear Precio_OLD__c del CSV o asignar un valor por defecto
            if (tankData.containsKey('Precio_OLD__c') && tankData.get('Precio_OLD__c') != null) {
                // Se asegura que el valor sea String antes de la conversión a Decimal
                newTank.Precio_OLD__c = Decimal.valueOf(String.valueOf(tankData.get('Precio_OLD__c')));
            } else {
                // ASIGNAR VALOR POR DEFECTO para que la inserción no falle por campo obligatorio.
                newTank.Precio_OLD__c = 0.01; // Un valor mínimo para satisfacer la obligatoriedad.
                System.debug('Precio_OLD__c no encontrado en CSV, asignando valor por defecto: ' + newTank.Precio_OLD__c);
            }

            tanksToInsert.add(newTank);
        }

        if (tanksToInsert.isEmpty()) {
            return 'No se encontraron tanques válidos para insertar.';
        }

        try {
            insert tanksToInsert;
            return 'Éxito: ' + tanksToInsert.size() + ' tanques creados correctamente.';
        } catch (DmlException e) {
            System.debug('DML Exception al insertar tanques: ' + e.getMessage());
            System.debug('Errores específicos de DML: ' + e.getDmlMessage(0));
            throw new AuraHandledException('Error al insertar tanques: ' + e.getMessage());
        }
    }

    /**
     * @Description: Método invocable desde LWC para obtener los Tipos de Tanque disponibles.
     * Esto se usará para el selector de Tipo de Tanque en la interfaz.
     * @return List<Map<String, String>> Una lista de mapas con 'label' y 'value' para el combobox.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTankTypes() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Tipo_de_Tanque__c tt : [SELECT Id, Name, Nombre_Tipo__c FROM Tipo_de_Tanque__c ORDER BY Name]) {
            options.add(new Map<String, String>{
                'label' => (tt.Nombre_Tipo__c != null ? tt.Nombre_Tipo__c : tt.Name),
                'value' => tt.Id
            });
        }
        return options;
    }
}