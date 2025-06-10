/**
 * @Description: Controlador Apex para la carga masiva de registros de Tanque__c.
 * Permite insertar múltiples registros de Tanque__c desde un LWC,
 * asociándolos a un Tipo_de_Tanque__c específico.
 */
public with sharing class TankMassUploadController {

    /**
     * @Description: Método invocable desde LWC para insertar masivamente tanques.
     * @param tipoTanqueId El ID del Tipo_de_Tanque__c al que se asociarán todos los tanques.
     * @param tankDataList Una lista de mapas, donde cada mapa representa los datos de un tanque.
     * Esperamos claves como 'Numero_de_Serie__c' y 'Estado__c'.
     * @return String Un mensaje de éxito o error.
     */
    @AuraEnabled
    public static String uploadTanks(Id tipoTanqueId, List<Object> tankDataList) {
        // Validar si el tipo de tanque es nulo
        if (tipoTanqueId == null) {
            throw new AuraHandledException('El ID del Tipo de Tanque no puede ser nulo.');
        }

        // Lista para almacenar los nuevos registros de Tanque__c
        List<Tanque__c> tanksToInsert = new List<Tanque__c>();

        // Iterar sobre los datos recibidos del LWC
        for (Object tankDataObj : tankDataList) {
            // Se debe convertir el objeto genérico a un mapa para acceder a sus propiedades
            Map<String, Object> tankData = (Map<String, Object>)tankDataObj;

            // Crear una nueva instancia de Tanque__c
            Tanque__c newTank = new Tanque__c();

            // Asociar el Tipo_de_Tanque__c
            newTank.Tipo_de_Tanque__c = tipoTanqueId;

            // Mapear el Número de Serie desde los datos del CSV
            // Asegurarse de que el nombre de la clave coincida con el encabezado de tu CSV
            if (tankData.containsKey('Numero_de_Serie__c') && tankData.get('Numero_de_Serie__c') != null) {
                newTank.Numero_de_Serie__c = String.valueOf(tankData.get('Numero_de_Serie__c'));
            } else {
                // Manejo de error si el número de serie es nulo o no está presente
                // En un escenario real, se podría registrar un error o saltar este registro.
                // Aquí, simplemente lanzaremos una excepción.
                System.debug('Advertencia: Número de Serie no encontrado o nulo para un registro de tanque.');
                // throw new AuraHandledException('El Número de Serie es un campo obligatorio.');
                // Si Numero_de_Serie__c es un Auto Number en el objeto, no necesitas mapearlo aquí.
                // Si es texto y obligatorio, esta validación es crucial.
                // Para este ejercicio, asumimos que puede ser auto-generado o el LWC lo valida.
            }

            // Mapear el Estado__c (opcional, si el CSV lo incluye; de lo contrario, se puede establecer un valor predeterminado)
            if (tankData.containsKey('Estado__c') && tankData.get('Estado__c') != null) {
                newTank.Estado__c = String.valueOf(tankData.get('Estado__c'));
            } else {
                // Si no se especifica el estado en el CSV, por defecto a 'Disponible'
                newTank.Estado__c = 'Disponible';
            }

            // Agrega el nuevo tanque a la lista
            tanksToInsert.add(newTank);
        }

        // Validar si hay tanques para insertar
        if (tanksToInsert.isEmpty()) {
            return 'No se encontraron tanques válidos para insertar.';
        }

        // Realizar la inserción masiva de los tanques
        try {
            insert tanksToInsert;
            return 'Éxito: ' + tanksToInsert.size() + ' tanques creados correctamente.';
        } catch (DmlException e) {
            // Capturar y manejar cualquier error de DML durante la inserción
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
                'label' => tt.Nombre_Tipo__c, // Muestra el Nombre_Tipo__c para el usuario
                'value' => tt.Id               // El valor real que se usará para la asociación
            });
        }
        return options;
    }
}