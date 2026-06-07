import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class DriveService {
  static final DriveService instance = DriveService._init();

  DriveService._init();

  /// Gets the directory where simulated Google Drive files are kept
  Future<Directory> _getSimulatedDriveDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final driveDir = Directory(p.join(appDir.path, 'simulated_google_drive'));
    if (!await driveDir.exists()) {
      await driveDir.create(recursive: true);
    }
    return driveDir;
  }

  /// Searches for a folder named 'My Wallet Backups' in the root of the user's Google Drive.
  /// If it doesn't exist, creates it and returns its ID.
  Future<String> _getOrCreateFolderId(drive.DriveApi driveApi) async {
    final folderName = 'My Wallet Backups';
    
    // Search for a non-trashed folder with this name in the user's primary Drive
    final folderList = await driveApi.files.list(
      q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
    );
    
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id!;
    }
    
    // Not found, create it
    final drive.File folderMetadata = drive.File();
    folderMetadata.name = folderName;
    folderMetadata.mimeType = 'application/vnd.google-apps.folder';
    folderMetadata.parents = ['root']; // Explicitly place it in the root folder of My Drive
    
    final createdFolder = await driveApi.files.create(folderMetadata);
    return createdFolder.id!;
  }

  /// Uploads or saves an encrypted file
  Future<bool> uploadFile({
    required String fileName,
    required String encryptedData,
    Map<String, String>? authHeaders,
    bool simulate = true,
  }) async {
    if (simulate) {
      // Simulate network transfer
      await Future.delayed(const Duration(milliseconds: 1000));
      final driveDir = await _getSimulatedDriveDir();
      final file = File(p.join(driveDir.path, fileName));
      await file.writeAsString(encryptedData);
      return true;
    }

    if (authHeaders == null) {
      throw Exception("User is not authenticated with Google.");
    }

    try {
      final client = AuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      // Get or create visible folder 'My Wallet Backups'
      final folderId = await _getOrCreateFolderId(driveApi);

      // Search if file already exists in 'My Wallet Backups' folder
      final fileList = await driveApi.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
      );

      final drive.File fileMetadata = drive.File();
      fileMetadata.name = fileName;

      final bytes = utf8.encode(encryptedData);
      final mediaStream = Stream.value(bytes);
      final media = drive.Media(mediaStream, bytes.length);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(
          fileMetadata,
          existingFileId,
          uploadMedia: media,
        );
      } else {
        // Create new file inside folder
        fileMetadata.parents = [folderId];
        await driveApi.files.create(
          fileMetadata,
          uploadMedia: media,
        );
      }
      return true;
    } catch (e) {
      throw Exception("Failed to upload to Google Drive: $e");
    }
  }

  /// Downloads or retrieves an encrypted file
  Future<String?> downloadFile({
    required String fileName,
    Map<String, String>? authHeaders,
    bool simulate = true,
  }) async {
    if (simulate) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final driveDir = await _getSimulatedDriveDir();
      final file = File(p.join(driveDir.path, fileName));
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    }

    if (authHeaders == null) {
      throw Exception("User is not authenticated with Google.");
    }

    try {
      final client = AuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      // Search if folder exists
      final folderList = await driveApi.files.list(
        q: "name = 'My Wallet Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (folderList.files == null || folderList.files!.isEmpty) {
        return null;
      }
      final folderId = folderList.files!.first.id!;

      // Search if file exists inside folder
      final fileList = await driveApi.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        final drive.Media media = await driveApi.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final List<int> dataBytes = [];
        await for (final chunk in media.stream) {
          dataBytes.addAll(chunk);
        }
        return utf8.decode(dataBytes);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to download from Google Drive: $e");
    }
  }

  /// Verifies if a backup exists in simulated or actual Drive
  Future<bool> hasBackup({
    Map<String, String>? authHeaders,
    bool simulate = true,
  }) async {
    if (simulate) {
      final driveDir = await _getSimulatedDriveDir();
      final accountsFile = File(p.join(driveDir.path, 'wallet_data.enc'));
      return await accountsFile.exists();
    }

    if (authHeaders == null) return false;

    try {
      final client = AuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      // Search if folder exists
      final folderList = await driveApi.files.list(
        q: "name = 'My Wallet Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (folderList.files == null || folderList.files!.isEmpty) {
        return false;
      }
      final folderId = folderList.files!.first.id!;

      final fileList = await driveApi.files.list(
        q: "name = 'wallet_data.enc' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
      );
      return fileList.files != null && fileList.files!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clears the simulated Drive files
  Future<void> clearSimulatedDrive() async {
    final driveDir = await _getSimulatedDriveDir();
    if (await driveDir.exists()) {
      await driveDir.delete(recursive: true);
    }
  }
}
