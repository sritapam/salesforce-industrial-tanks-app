import { LightningElement, api, track } from 'lwc';

export default class CustomToast extends LightningElement {
    @api message = ''; // Mensaje a mostrar en el toast
    @api variant = 'info'; // Variante del toast: 'success', 'error', 'warning', 'info'

    @track isVisible = false; // Controla la visibilidad del toast

    // Icono dinámico basado en la variante
    get iconName() {
        switch (this.variant) {
            case 'success':
                return 'utility:success';
            case 'error':
                return 'utility:error';
            case 'warning':
                return 'utility:warning';
            default:
                return 'utility:info';
        }
    }

    // Clases CSS dinámicas para el tema del toast
    get toastClass() {
        let classes = 'slds-notify slds-notify_alert';
        switch (this.variant) {
            case 'success':
                classes += ' slds-theme_success';
                break;
            case 'error':
                classes += ' slds-theme_error';
                break;
            case 'warning':
                classes += ' slds-theme_warning';
                break;
            default:
                classes += ' slds-theme_info'; // O 'slds-theme_alert' si prefieres para info
                break;
        }
        return classes;
    }

    // Hook del ciclo de vida para mostrar el toast cuando las propiedades cambian
    connectedCallback() {
        this.isVisible = true;
        // Opcional: Cerrar el toast automáticamente después de un tiempo
        // setTimeout(() => {
        //     this.handleClose();
        // }, 5000); // Cierra después de 5 segundos
    }

    // Maneja el evento de cerrar el toast
    handleClose() {
        this.isVisible = false;
        // Despacha un evento 'close' para que el componente padre pueda reaccionar
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}
