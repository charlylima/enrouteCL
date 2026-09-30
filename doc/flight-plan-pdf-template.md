# Flight plan PDF export

The route editor exports flight plans as PDF through its **Export…** menu. The
export uses Qt's `QTextDocument` and `QPdfWriter` and supports A5 and A6 paper in
portrait or landscape orientation. On Android, use **Share…** to send the PDF
to another application or **Save…** to choose a destination with the system
document picker; the application does not request broad storage permissions.
Direct Android PrintManager integration is not included. To print, share or
open the generated PDF in an installed PDF application and use that application's
print action.

The default, text-based HTML template is
[`src/templates/flightplan.html`](../src/templates/flightplan.html). It uses
the HTML subset supported by `QTextDocument`, with `{{title}}` and `{{rows}}`
placeholders. The exporter HTML-escapes all route data before inserting it.
You can customize the template's text and simple CSS, then rebuild the
application to bundle the changes. Keep the placeholders intact.
