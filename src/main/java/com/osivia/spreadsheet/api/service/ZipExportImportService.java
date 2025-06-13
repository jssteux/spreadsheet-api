package com.osivia.spreadsheet.api.service;

import com.opencsv.exceptions.CsvValidationException;
import com.osivia.spreadsheet.api.entity.*;
import com.osivia.spreadsheet.api.exception.ResourceNotFoundException;
import com.osivia.spreadsheet.api.repository.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.opencsv.CSVReader;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Stream;
import java.util.zip.*;


@Service
public class ZipExportImportService {


    private final SpreadsheetRepository spreadsheetRepository;


    private final  SheetRepository sheetRepository;


    private final  CellRepository cellRepository;


    private final  MediaRepository mediaRepository;


    private final  UserRepository userRepository;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public ZipExportImportService(SpreadsheetRepository spreadsheetRepository, SheetRepository sheetRepository, CellRepository cellRepository, MediaRepository mediaRepository, UserRepository userRepository) {
        this.spreadsheetRepository = spreadsheetRepository;
        this.sheetRepository = sheetRepository;
        this.cellRepository = cellRepository;
        this.mediaRepository = mediaRepository;
        this.userRepository = userRepository;
    }

    // DTO pour metadata.json (sans les données des cellules)
    public static class SpreadsheetMetadata {
        public String name;
        public String description;
        public List<SheetMetadata> sheets = new ArrayList<>();
        public List<MediaMetadata> mediaFiles = new ArrayList<>();
    }

    public static class SheetMetadata {
        public String name;
        public String filename; // nom du fichier CSV
    }

    public static class MediaMetadata {
        public String filename;
        public String contentType;
        public Long size;
    }

    /**
     * Exporte un spreadsheet complet en fichier ZIP
     */
    @Transactional(readOnly = true)
    public byte[] exportSpreadsheetToZip(Long spreadsheetId) throws IOException {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
                .orElseThrow(() -> new RuntimeException("Spreadsheet not found"));

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            // 1. Créer le metadata JSON (sans les données des cellules)
            SpreadsheetMetadata metadata = new SpreadsheetMetadata();
            metadata.name = spreadsheet.getName();
            metadata.description = spreadsheet.getDescription();

            // 2. Exporter chaque sheet en CSV
            for (Sheet sheet : spreadsheet.getSheets()) {
                String csvFilename = sanitizeFilename(sheet.getName()) + ".csv";

                // Ajouter les métadonnées du sheet
                SheetMetadata sheetMeta = new SheetMetadata();
                sheetMeta.name = sheet.getName();
                sheetMeta.filename = csvFilename;
                metadata.sheets.add(sheetMeta);

                // Créer le fichier CSV dans le ZIP
                ZipEntry csvEntry = new ZipEntry("sheets/" + csvFilename);
                zos.putNextEntry(csvEntry);
                writeSheetToCsv(sheet, zos);
                zos.closeEntry();
            }

            // 3. Ajouter les métadonnées des fichiers média
            for (Media media : spreadsheet.getMediaFiles()) {
                MediaMetadata mediaMeta = new MediaMetadata();
                mediaMeta.filename = media.getFilename();
                mediaMeta.contentType = media.getContentType();
                mediaMeta.size = media.getFileSize();
                metadata.mediaFiles.add(mediaMeta);
            }

            // 4. Ajouter metadata.json au ZIP
            ZipEntry metadataEntry = new ZipEntry("metadata.json");
            zos.putNextEntry(metadataEntry);
            zos.write(objectMapper.writerWithDefaultPrettyPrinter()
                    .writeValueAsBytes(metadata));
            zos.closeEntry();

            // 5. Ajouter les fichiers média au ZIP
            for (Media media : spreadsheet.getMediaFiles()) {
                Path filePath = Paths.get(uploadDir, media.getFilename());
                if (Files.exists(filePath)) {
                    ZipEntry mediaEntry = new ZipEntry("media/" + media.getFilename());
                    zos.putNextEntry(mediaEntry);
                    Files.copy(filePath, zos);
                    zos.closeEntry();
                }
            }
        }

        return baos.toByteArray();
    }


    /**
     * Écrit les données d'un sheet au format CSV (version simple sans OpenCSV)
     */
    private void writeSheetToCsv(Sheet sheet, OutputStream outputStream) throws IOException {
        // Trouver les dimensions maximales
        int maxRow = 0;
        int maxCol = 0;

        Map<String, Cell> cellMap = new HashMap<>();
        for (Cell cell : sheet.getCells()) {
            String key = cell.getRowIndex() + "," + cell.getColumnIndex();
            cellMap.put(key, cell);
            maxRow = Math.max(maxRow, cell.getRowIndex());
            maxCol = Math.max(maxCol, cell.getColumnIndex());
        }

        // Écrire directement avec PrintWriter (ne ferme pas le stream sous-jacent)
        PrintWriter writer = new PrintWriter(new OutputStreamWriter(outputStream, StandardCharsets.UTF_8));

        for (int row = 0; row <= maxRow; row++) {
            StringBuilder line = new StringBuilder();

            for (int col = 0; col <= maxCol; col++) {
                if (col > 0) {
                    line.append(",");
                }

                Cell cell = cellMap.get(row + "," + col);
                String value = cell != null ? cell.getValue() : "";

                // Échapper les valeurs si nécessaire
                if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
                    value = "\"" + value.replace("\"", "\"\"") + "\"";
                }

                line.append(value);
            }

            writer.println(line.toString());
        }

        writer.flush(); // Important: flush mais ne pas close
    }

    /**
     * Importe un spreadsheet depuis un fichier ZIP
     */
    @Transactional
    public Spreadsheet importSpreadsheetFromZip(MultipartFile zipFile, String userName) throws IOException {
        // Créer un répertoire temporaire pour extraire le ZIP
        Path tempDir = Files.createTempDirectory("spreadsheet-import-");

        try {
            // Debug : lister le contenu du ZIP
            //debugZipContent(zipFile.getInputStream());

            // Extraire le ZIP
            extractZip(zipFile.getInputStream(), tempDir);

            // Lire metadata.json
            Path metadataPath = tempDir.resolve("metadata.json");
            if (!Files.exists(metadataPath)) {
                throw new RuntimeException("Invalid ZIP: metadata.json not found");
            }

            SpreadsheetMetadata metadata = objectMapper.readValue(
                    Files.readAllBytes(metadataPath),
                    SpreadsheetMetadata.class
            );

            // Créer le nouveau spreadsheet
            Spreadsheet spreadsheet = new Spreadsheet();
            spreadsheet.setName(metadata.name);
            spreadsheet.setDescription(metadata.description);
            User user = userRepository.findByUsername(userName)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found"));
            spreadsheet.setOwner(user);
            spreadsheet = spreadsheetRepository.save(spreadsheet);

            // Créer les sheets depuis les fichiers CSV
            Path sheetsDir = tempDir.resolve("sheets");


            if (Files.exists(sheetsDir)) {
                int order =0;
                for (SheetMetadata sheetMeta : metadata.sheets) {
                    Path csvPath = sheetsDir.resolve(sheetMeta.filename);
                    System.out.println("Looking for CSV: " + csvPath);

                    if (Files.exists(csvPath)) {
                        Sheet sheet = new Sheet();
                        sheet.setName(sheetMeta.name);
                        sheet.setSpreadsheet(spreadsheet);
                        sheet.setOrderIndex( order++);
                        sheet = sheetRepository.save(sheet);

                        // Lire le CSV et créer les cellules
                        importCellsFromCsv(csvPath, sheet);
                    } else {
                        System.err.println("CSV file not found: " + csvPath);
                    }
                }
            } else {
                System.err.println("Sheets directory not found: " + sheetsDir);
            }

            // Copier les fichiers média
            Path mediaDir = tempDir.resolve("media");
            if (Files.exists(mediaDir)) {
                for (MediaMetadata mediaMeta : metadata.mediaFiles) {
                    Path sourcePath = mediaDir.resolve(mediaMeta.filename);
                    if (Files.exists(sourcePath)) {
                        // Générer un nouveau nom de fichier unique
                        String extension = "";
                        int lastDot = mediaMeta.filename.lastIndexOf('.');
                        if (lastDot > 0) {
                            extension = mediaMeta.filename.substring(lastDot);
                        }
                        String newFilename = UUID.randomUUID().toString() + extension;
                        Path targetPath = Paths.get(uploadDir, newFilename);

                        // Créer le répertoire s'il n'existe pas
                        Files.createDirectories(targetPath.getParent());

                        // Copier le fichier
                        Files.copy(sourcePath, targetPath);

                        // Créer l'entrée Media
                        Media media = new Media();
                        media.setFilename(newFilename);
                        media.setContentType(mediaMeta.contentType);
                        media.setFileSize(mediaMeta.size);
                        media.setSpreadsheet(spreadsheet);
                        mediaRepository.save(media);
                    }
                }
            }

            return spreadsheet;

        } finally {
            // Nettoyer le répertoire temporaire
            deleteDirectory(tempDir);
        }
    }

    /**
     * Importe les cellules depuis un fichier CSV
     */
    private void importCellsFromCsv(Path csvPath, Sheet sheet) throws IOException {
        try (Reader reader = Files.newBufferedReader(csvPath);
             CSVReader csvReader = new CSVReader(reader)) {

            String[] nextLine;
            int row = 0;

            while ((nextLine = csvReader.readNext()) != null) {
                for (int col = 0; col < nextLine.length; col++) {
                    String value = nextLine[col];
                    if (value != null && !value.isEmpty()) {
                        Cell cell = new Cell();
                        cell.setRowIndex(row);
                        cell.setColumnIndex(col);
                        cell.setValue(value);
                        cell.setSheet(sheet);
                        cellRepository.save(cell);
                    }
                }
                row++;
            }
        } catch (CsvValidationException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Nettoie le nom de fichier pour éviter les caractères problématiques
     */
    private String sanitizeFilename(String filename) {
        return filename.replaceAll("[^a-zA-Z0-9.-]", "_");
    }

    /**
     * Extrait un fichier ZIP dans un répertoire
     */
    private void extractZip(InputStream zipInputStream, Path targetDir) throws IOException {
        try (ZipInputStream zis = new ZipInputStream(zipInputStream)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                // Normaliser le nom pour gérer les séparateurs Windows/Unix
                String entryName = entry.getName().replace('\\', '/');
                Path targetPath = targetDir.resolve(entryName);

                if (entry.isDirectory()) {
                    Files.createDirectories(targetPath);
                } else {
                    // S'assurer que le répertoire parent existe
                    Files.createDirectories(targetPath.getParent());
                    Files.copy(zis, targetPath, StandardCopyOption.REPLACE_EXISTING);
                }

                zis.closeEntry();
            }
        }
    }

    /**
     * Déboguer le contenu d'un ZIP
     */
    private void debugZipContent(InputStream zipInputStream) throws IOException {
        System.out.println("=== DEBUG ZIP CONTENT ===");
        try (ZipInputStream zis = new ZipInputStream(zipInputStream)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                System.out.println("Entry: " + entry.getName() +
                        " (isDirectory: " + entry.isDirectory() +
                        ", size: " + entry.getSize() + ")");
                zis.closeEntry();
            }
        }
        System.out.println("=== END DEBUG ===");
    }

    /**
     * Supprime récursivement un répertoire
     */
    private void deleteDirectory(Path dir) throws IOException {
        if (Files.exists(dir)) {
            try (Stream<Path> paths = Files.walk(dir)) {
                paths.sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            try {
                                Files.delete(path);
                            } catch (IOException e) {
                                // Log error but continue
                                System.err.println("Failed to delete: " + path + " - " + e.getMessage());
                            }
                        });
            }
        }
    }
}