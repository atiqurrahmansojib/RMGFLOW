package com.rmgflow.report.service;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.rmgflow.report.dto.ReportColumn;
import com.rmgflow.report.dto.ReportResultResponse;
import com.rmgflow.report.dto.ReportSummaryItem;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Renders an already-run report (same rows/summary the API returns) as CSV or PDF. */
@Service
public class ReportExportService {

    private static final byte[] UTF8_BOM = {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
    private static final DateTimeFormatter GENERATED_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final Set<String> NUMERIC_TYPES = Set.of("number", "money", "percent");
    private static final Color HEADER_BACKGROUND = new Color(31, 78, 121);
    private static final Color STRIPE_BACKGROUND = new Color(242, 246, 250);

    /**
     * UTF-8 with a BOM so Excel detects the encoding (Bangla/accented names stay
     * intact). Layout: header row, data rows, then a blank line and the summary
     * block, so the file still opens as a clean table.
     */
    public byte[] toCsv(ReportResultResponse report, List<String> filterLines) {
        StringBuilder csv = new StringBuilder();
        List<ReportColumn> columns = report.columns();
        csv.append(String.join(",", columns.stream().map(c -> csvCell(c.label())).toList())).append("\r\n");
        for (Map<String, Object> row : report.rows()) {
            csv.append(String.join(",", columns.stream().map(c -> csvCell(row.get(c.key()))).toList())).append("\r\n");
        }
        csv.append("\r\n");
        csv.append(csvCell("Report")).append(',').append(csvCell(report.name())).append("\r\n");
        csv.append(csvCell("Generated")).append(',').append(csvCell(report.generatedAt().format(GENERATED_FORMAT))).append("\r\n");
        for (String line : filterLines) {
            csv.append(csvCell("Filter")).append(',').append(csvCell(line)).append("\r\n");
        }
        for (ReportSummaryItem item : report.summary()) {
            csv.append(csvCell(item.label())).append(',').append(csvCell(item.value())).append("\r\n");
        }
        byte[] body = csv.toString().getBytes(StandardCharsets.UTF_8);
        byte[] out = new byte[UTF8_BOM.length + body.length];
        System.arraycopy(UTF8_BOM, 0, out, 0, UTF8_BOM.length);
        System.arraycopy(body, 0, out, UTF8_BOM.length, body.length);
        return out;
    }

    /** Landscape A4: title, generated time, applied filters, summary table, then the data table. */
    public byte[] toPdf(ReportResultResponse report, List<String> filterLines) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4.rotate(), 24, 24, 28, 28);
        try {
            PdfWriter.getInstance(document, out);
            document.addTitle(report.name());
            document.addCreator("RMGFlow");
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, HEADER_BACKGROUND);
            Font metaFont = FontFactory.getFont(FontFactory.HELVETICA, 9, Color.DARK_GRAY);
            Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
            Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7.5f, Color.WHITE);
            Font cellFont = FontFactory.getFont(FontFactory.HELVETICA, 7.5f);

            document.add(new Paragraph(report.name(), titleFont));
            document.add(new Paragraph("Generated: " + report.generatedAt().format(GENERATED_FORMAT)
                    + "   |   Rows: " + report.rows().size(), metaFont));
            document.add(new Paragraph("Filters: " + (filterLines.isEmpty() ? "none" : String.join("; ", filterLines)), metaFont));
            document.add(Chunk.NEWLINE);

            if (!report.summary().isEmpty()) {
                document.add(new Paragraph("Summary", sectionFont));
                PdfPTable summary = new PdfPTable(4);
                summary.setWidthPercentage(70);
                summary.setHorizontalAlignment(Element.ALIGN_LEFT);
                summary.setSpacingBefore(4);
                summary.setSpacingAfter(10);
                for (ReportSummaryItem item : report.summary()) {
                    summary.addCell(cell(item.label(), cellFont, Element.ALIGN_LEFT, STRIPE_BACKGROUND));
                    summary.addCell(cell(format(item.value(), null), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7.5f),
                            Element.ALIGN_RIGHT, null));
                }
                summary.completeRow();
                document.add(summary);
            }

            List<ReportColumn> columns = report.columns();
            PdfPTable table = new PdfPTable(columns.size());
            table.setWidthPercentage(100);
            table.setHeaderRows(1);
            for (ReportColumn column : columns) {
                table.addCell(cell(column.label(), headerFont, Element.ALIGN_CENTER, HEADER_BACKGROUND));
            }
            int index = 0;
            for (Map<String, Object> row : report.rows()) {
                Color background = (index++ % 2 == 1) ? STRIPE_BACKGROUND : null;
                for (ReportColumn column : columns) {
                    int align = NUMERIC_TYPES.contains(column.type()) ? Element.ALIGN_RIGHT : Element.ALIGN_LEFT;
                    table.addCell(cell(format(row.get(column.key()), column.type()), cellFont, align, background));
                }
            }
            if (report.rows().isEmpty()) {
                PdfPCell empty = cell("No data for the selected filters", cellFont, Element.ALIGN_CENTER, null);
                empty.setColspan(columns.size());
                table.addCell(empty);
            }
            document.add(table);
        } catch (DocumentException ex) {
            throw new IllegalStateException("Failed to render PDF report", ex);
        } finally {
            if (document.isOpen()) {
                document.close();
            }
        }
        return out.toByteArray();
    }

    private static PdfPCell cell(String text, Font font, int align, Color background) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(align);
        cell.setPadding(3);
        cell.setBorderColor(new Color(200, 205, 210));
        if (background != null) {
            cell.setBackgroundColor(background);
        }
        return cell;
    }

    private static String format(Object value, String type) {
        if (value == null) {
            return "";
        }
        if (value instanceof BigDecimal decimal) {
            String formatted = new DecimalFormat("#,##0.00").format(decimal);
            return "percent".equals(type) ? formatted + "%" : formatted;
        }
        if (value instanceof Number number && "number".equals(type)) {
            return new DecimalFormat("#,##0").format(number);
        }
        return value.toString();
    }

    private static String csvCell(Object value) {
        if (value == null) {
            return "";
        }
        String text = value.toString();
        // Neutralize spreadsheet formula injection for text that starts with =, +, - or @.
        if (!text.isEmpty() && "=+-@".indexOf(text.charAt(0)) >= 0 && !(value instanceof Number)) {
            text = "'" + text;
        }
        if (text.contains(",") || text.contains("\"") || text.contains("\n") || text.contains("\r")) {
            return "\"" + text.replace("\"", "\"\"") + "\"";
        }
        return text;
    }
}
