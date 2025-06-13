import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader'; // Para cargar librerías externas como PapaParse

// Importar el recurso estático de PapaParse (asegúrate de haberlo subido con el nombre 'PapaParse')
import PAPAPARSE from '@salesforce/resourceUrl/PapaParse';

// Importar métodos Apex
import getTankTypes from '@salesforce/apex/TankMassUploadController.getTankTypes';
import uploadTanks from '@salesforce/apex/TankMassUploadController.uploadTanks';

export default class TankMassUploader extends LightningElement {
    // Propiedades API para recibir valores del App Builder o Record Page
    @api recordId; // Para cuando el LWC está en una Record Page de Tipo_de_Tanque__c
    @api tipoDeTanquePorDefecto; // Para cuando el LWC está en una App Page

    // Propiedades reactivas para la interfaz de usuario
    @track selectedTankTypeId; // ID del Tipo de Tanque seleccionado
    @track tankTypeOptions = []; // Opciones para el combobox de Tipo de Tanque
    @track parsedData = []; // Datos parseados del CSV (¡para enviar a Apex!)
    @track previewData = []; // Datos transformados para la previsualización en la tabla HTML
    @track csvHeaders = []; // Encabezados del CSV
    @track isLoading = false; // Controla el spinner de carga
    @track showToast = false; // Controla la visibilidad del Custom Toast
    @track toastMessage = ''; // Mensaje del Custom Toast
    @track toastVariant = ''; // Variante del Custom Toast (success, error, warning)

    // Propiedades para PapaParse
    papaParseInitialized = false;

    // Getter para deshabilitar el botón de carga si no hay tipo de tanque o datos parseados
    get isUploadDisabled() {
        return !this.selectedTankTypeId || this.parsedData.length === 0;
    }

    /*
     * @Description: Hook del ciclo de vida que se ejecuta cuando el componente se inserta en el DOM.
     * Aquí cargamos la librería PapaParse y obtenemos los tipos de tanque.
     * @param: None
     * @return: void
     */
    connectedCallback() {
        // Inicializar PapaParse una vez
        if (!this.papaParseInitialized) {
            Promise.all([
                loadScript(this, PAPAPARSE)
            ])
            .then(() => {
                this.papaParseInitialized = true;
                console.log('PapaParse cargado con éxito');
            })
            .catch(error => {
                console.error('Error al cargar PapaParse:', error);
                this.showToastMessage('Error al cargar la librería PapaParse: ' + error.message, 'error');
            });
        }

        // Si el componente está en una Record Page de Tipo_de_Tanque__c, preseleccionar ese ID
        if (this.recordId) {
            this.selectedTankTypeId = this.recordId;
        } else if (this.tipoDeTanquePorDefecto) {
            // Si el componente está en una App Page y se le pasa un ID por defecto
            this.selectedTankTypeId = this.tipoDeTanquePorDefecto;
        }
    }

    /*
     * @Description: Método Wire para obtener los tipos de tanque de Apex.
     * El decorador @wire es reactivo; se invoca automáticamente.
     * @param: result - Objeto que contiene data o error.
     * @return: void
     * Para la entrevista: Explica que @wire es un "adaptador de servicio"
     * para llamar métodos Apex (u otros servicios) de forma declarativa.
     * 'cacheable=true' mejora el rendimiento al guardar en caché los resultados.
     */
    @wire(getTankTypes)
    wiredTankTypes({ error, data }) {
        if (data) {
            this.tankTypeOptions = data;
            // Si no hay un tipo de tanque preseleccionado, seleccionar el primero si existe
            if (!this.selectedTankTypeId && data.length > 0) {
                this.selectedTankTypeId = data[0].value;
            }
        } else if (error) {
            console.error('Error al obtener tipos de tanque:', error);
            this.showToastMessage('Error al cargar tipos de tanque: ' + error.body.message, 'error');
        }
    }

    /*
     * @Description: Maneja el cambio en la selección del Tipo de Tanque en el combobox.
     * @param: event - Evento de cambio del input.
     * @return: void
     */
    handleTankTypeChange(event) {
        this.selectedTankTypeId = event.detail.value;
        console.log('Tipo de Tanque seleccionado:', this.selectedTankTypeId);
    }

    /*
     * @Description: Maneja la carga del archivo CSV. Utiliza PapaParse para analizar el archivo.
     * @param: event - Evento de cambio del input de tipo 'file'.
     * @return: void
     * Para la entrevista: Destaca el uso de PapaParse para procesar el CSV en el lado del cliente,
     * lo cual es eficiente y no consume límites de heap del servidor de Salesforce hasta que se envían los datos.
     */
    handleFileUpload(event) {
        if (!this.papaParseInitialized) {
            this.showToastMessage('Librería PapaParse no cargada. Intente de nuevo más tarde.', 'error');
            return;
        }

        const file = event.target.files[0];
        if (file) {
            this.isLoading = true;
            // Usar PapaParse para parsear el archivo CSV
            Papa.parse(file, {
                header: true, // Asume que la primera fila son los encabezados
                skipEmptyLines: true, // Ignora líneas vacías
                complete: (results) => {
                    this.parsedData = results.data; // Datos crudos para Apex

                    this.csvHeaders = results.meta.fields.map(field => ({ label: field, value: field }));

                    // TRANSFORMAR DATOS PARA LA PREVISUALIZACIÓN EN HTML (EVITA ACCESO COMPUTADO)
                    this.previewData = this.parsedData.map((row, index) => {
                        const transformedRow = {
                            key: index, // Usar el índice como key para la fila de previsualización (es suficiente para esto)
                            cells: this.csvHeaders.map(header => ({
                                value: row[header.value], // Acceder al valor usando corchetes en JS (permitido)
                                key: header.value // Usar el nombre del campo como key para la celda
                            }))
                        };
                        return transformedRow;
                    });


                    this.isLoading = false;
                    console.log('Datos CSV parseados (para Apex):', this.parsedData);
                    console.log('Datos CSV para previsualización (HTML):', this.previewData);
                    this.showToastMessage('Archivo CSV cargado y previsualizado correctamente.', 'success');
                },
                error: (error) => {
                    this.isLoading = false;
                    console.error('Error al parsear CSV:', error);
                    this.showToastMessage('Error al leer el archivo CSV: ' + error.message, 'error');
                }
            });
        }
    }

    /*
     * @Description: Maneja el proceso de carga de los tanques a Salesforce llamando al método Apex.
     * @param: None
     * @return: void
     * Para la entrevista: Explica la llamada imperativa a Apex, cómo se pasa la lista de objetos
     * y cómo se manejan los resultados (éxito/error). Menciona la eficiencia de la inserción DML masiva en Apex.
     */
    handleUploadTanks() {
        if (!this.selectedTankTypeId) {
            this.showToastMessage('Por favor, seleccione un Tipo de Tanque.', 'warning');
            return;
        }
        if (this.parsedData.length === 0) {
            this.showToastMessage('Por favor, cargue un archivo CSV con datos de tanques.', 'warning');
            return;
        }

        this.isLoading = true;

        // Llamada imperativa al método Apex
        uploadTanks({
            tipoTanqueId: this.selectedTankTypeId,
            tankDataList: this.parsedData
        })
        .then(result => {
            this.isLoading = false;
            console.log('Resultado de la carga Apex:', result);
            this.showToastMessage(result, 'success'); // Mostrar el mensaje de éxito de Apex
            this.handleReset(); // Restablecer el componente después de una carga exitosa
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error en la carga masiva de tanques:', error);
            // Mostrar un mensaje de error más amigable desde AuraHandledException de Apex
            let errorMessage = 'Error desconocido al crear tanques.';
            if (error && error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error && error.message) {
                 errorMessage = error.message;
            }
            this.showToastMessage('Error: ' + errorMessage, 'error');
        });
    }

    /*
     * @Description: Restablece el estado del componente.
     * @param: None
     * @return: void
     */
    handleReset() {
        this.selectedTankTypeId = this.recordId || this.tipoDeTanquePorDefecto || (this.tankTypeOptions.length > 0 ? this.tankTypeOptions[0].value : null);
        this.parsedData = [];
        this.previewData = []; // Limpiar también los datos de previsualización
        this.csvHeaders = [];
        this.template.querySelector('lightning-input[type="file"]').value = ''; // Limpiar el input de archivo
        this.isLoading = false;
        console.log('Componente restablecido.');
    }

    /*
     * @Description: Muestra un mensaje Toast personalizado.
     * @param: message - El texto del mensaje.
     * @param: variant - El tipo de mensaje (success, error, warning).
     * @return: void
     */
    showToastMessage(message, variant) {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;
    }

    /*
     * @Description: Cierra el mensaje Toast personalizado.
     * @param: None
     * @return: void
     */
    handleCloseToast() {
        this.showToast = false;
        this.toastMessage = '';
        this.toastVariant = '';
    }
}
