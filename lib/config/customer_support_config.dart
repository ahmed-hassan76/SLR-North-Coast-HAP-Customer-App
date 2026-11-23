// Shared resident support contacts.
enum SupportContact {
  hotline('Hotline', '19172'),
  email('Email', 'info@hap.com.eg'),
  whatsApp('WhatsApp', '+201002765455');

  const SupportContact(this.label, this.value);
  final String label;
  final String value;
}
