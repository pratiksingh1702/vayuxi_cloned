# Manpower Field Mapping API Documentation

## Overview

The Manpower Field Mapping feature allows users to upload Excel/CSV files and map columns to manpower model fields through a user-friendly interface. This eliminates the need for complex field matching logic and gives users full control over how their data is imported.

## Architecture

### Components

1. **Model**: `ManpowerFieldMappingModel` - Stores field mapping configurations
2. **APIs**: 
   - `/api/v1/manpower/field-mapping/preview` - Analyze uploaded file
   - `/api/v1/manpower/field-mapping/save` - Save/Get/Delete mapping configurations
   - `/api/v1/manpower/field-mapping/import` - Import with custom mapping
3. **Service**: `ManpowerFlexibleUploadService.importWithCustomMapping()` - Import logic
4. **UI Component**: `ManpowerFieldMapping.tsx` - React component for dashboard

### Workflow

### Standard Template Flow (Auto-Import)
```
1. User uploads Excel/CSV file in standard template format
   ↓
2. System detects standard template automatically
   ↓
3. User can click "Import Now" to skip mapping step
   ↓
4. System creates manpower records immediately
```

### Custom File Flow (Manual Mapping)
```
1. User uploads Excel/CSV file
   ↓
2. System analyzes file and suggests field mappings
   ↓
3. User reviews and adjusts mappings
   ↓
4. User optionally saves mapping configuration for reuse
   ↓
5. User imports data with custom mappings
   ↓
6. System creates manpower records
```

---

## Standard Template Format

### Download Standard Template

Users can download the standard manpower template to ensure their files are in the correct format for auto-import.

**Endpoint**: `GET /api/v1/templates/download?model=manpower`

**cURL Example**:
```bash
curl -X GET 'http://localhost:3000/api/v1/templates/download?model=manpower' \
  -H 'Cookie: your-session-cookie' \
  --output manpower_template.xlsx
```

### Standard Template Headers

The standard template includes these exact column headers (case-insensitive):

| Column Header | Maps To | Required | Description |
|---------------|---------|----------|-------------|
| SR NO | - | No | Serial number (ignored during import) |
| NAME | fullName | ✅ Yes | Employee's full name |
| DESIGNATION | designation | No | Job title/position |
| EMPLOYEE CODE | employeeCode | No | Unique employee identifier |
| PH NO | phoneNumber | No | Contact number |
| ADHAR NO | aaddharNumber | No | Aadhar card number |
| PAN NO | panNumber | No | PAN card number |
| BANK ACCOUNT NUMBER | bankAccountNumber | No | Bank account number |
| IFSC CODE | ifscCode | No | Bank IFSC code |
| ESIC NUMBER | esicNumber | No | ESIC number |
| DOB | dateOfBirth | No | Date of birth (DD.MM.YYYY or DD/MM/YYYY) |
| DOJ | dateOfJoining | No | Date of joining (DD.MM.YYYY or DD/MM/YYYY) |
| PF APPLICABLE | pfApplicable | No | PF applicable (YES/NO) |
| PAY BASIC | payBasics | No | Payment frequency (MONTHLY/YEARLY/DAILY/FIXED) |
| SALARY | salary | No | Total salary amount |
| BASIC | basicSalary | No | Basic salary component |
| HRA | hra | No | House Rent Allowance |
| DA | da | No | Dearness Allowance |
| SPC. ALLOW. | specialAllowance | No | Special allowance |
| TA | travelAllowance | No | Travel allowance |
| MED. ALLOW. | medicalAllowance | No | Medical allowance |
| TOTAL HOURS | totalHour | No | Working hours per day (default: 8) |
| REMARKS | remarks | No | Additional notes or comments |

### Auto-Detection Benefits

When the system detects a standard template:
- ✅ **Skip mapping step** - Import directly without manual field mapping
- ✅ **Faster import** - One-click import process
- ✅ **No errors** - Pre-validated field mappings
- ✅ **Consistent format** - Standardized across all imports

---

## API Endpoints

### 1. Preview File and Get Field Suggestions

**Endpoint**: `POST /api/v1/manpower/field-mapping/preview`

**Description**: Upload an Excel/CSV file to analyze its structure and get suggested field mappings.

**Authentication**: Required (Bearer token or session cookie)

**Request**:
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: Form data with file

**cURL Example**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/preview' \
  -H 'Cookie: your-session-cookie' \
  -F 'file=@/path/to/manpower.xlsx'
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "File analyzed successfully",
  "data": {
    "csvColumns": [
      "Employee Name",
      "Position",
      "Phone",
      "Salary",
      "Pay Type"
    ],
    "modelFields": [
      {
        "field": "fullName",
        "label": "Full Name",
        "required": true,
        "type": "string"
      },
      {
        "field": "designation",
        "label": "Designation",
        "required": false,
        "type": "string"
      },
      {
        "field": "phoneNumber",
        "label": "Phone Number",
        "required": false,
        "type": "string"
      },
      {
        "field": "salary",
        "label": "Salary",
        "required": false,
        "type": "number"
      },
      {
        "field": "payBasics",
        "label": "Pay Basics",
        "required": false,
        "type": "enum",
        "enumValues": ["daily", "monthly", "yearly", "fixed"]
      }
    ],
    "suggestedMappings": [
      {
        "csvColumn": "Employee Name",
        "modelField": "fullName",
        "confidence": 0.95
      },
      {
        "csvColumn": "Position",
        "modelField": "designation",
        "confidence": 0.92
      },
      {
        "csvColumn": "Phone",
        "modelField": "phoneNumber",
        "confidence": 0.88
      },
      {
        "csvColumn": "Salary",
        "modelField": "salary",
        "confidence": 0.95
      },
      {
        "csvColumn": "Pay Type",
        "modelField": "payBasics",
        "confidence": 0.85
      }
    ],
    "preview": [
      {
        "Employee Name": "John Doe",
        "Position": "Supervisor",
        "Phone": "9876543210",
        "Salary": "50000",
        "Pay Type": "monthly"
      },
      {
        "Employee Name": "Jane Smith",
        "Position": "Technician",
        "Phone": "9876543211",
        "Salary": "35000",
        "Pay Type": "monthly"
      }
    ],
    "unmappedColumns": []
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "error": "Invalid file type. Please upload an Excel file (.xlsx, .xls) or CSV file (.csv)"
}
```

---

### 2. Save Field Mapping Configuration

**Endpoint**: `POST /api/v1/manpower/field-mapping/save`

**Description**: Save a field mapping configuration for future reuse.

**Authentication**: Required

**Request**:
- Method: `POST`
- Content-Type: `application/json`

**Body**:
```json
{
  "configurationName": "Standard Employee Import",
  "type": "mechanical_work",
  "mappings": [
    {
      "csvColumn": "Employee Name",
      "modelField": "fullName"
    },
    {
      "csvColumn": "Position",
      "modelField": "designation"
    },
    {
      "csvColumn": "Phone",
      "modelField": "phoneNumber"
    },
    {
      "csvColumn": "Salary",
      "modelField": "salary"
    },
    {
      "csvColumn": "Pay Type",
      "modelField": "payBasics"
    }
  ],
  "isDefault": false
}
```

**cURL Example**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/save' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: your-session-cookie' \
  -d '{
    "configurationName": "Standard Employee Import",
    "type": "mechanical_work",
    "mappings": [
      {"csvColumn": "Employee Name", "modelField": "fullName"},
      {"csvColumn": "Position", "modelField": "designation"},
      {"csvColumn": "Phone", "modelField": "phoneNumber"},
      {"csvColumn": "Salary", "modelField": "salary"},
      {"csvColumn": "Pay Type", "modelField": "payBasics"}
    ],
    "isDefault": false
  }'
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Field mapping configuration saved successfully",
  "data": {
    "_id": "64a1b2c3d4e5f6g7h8i9j0k1",
    "company": "64a1b2c3d4e5f6g7h8i9j0k2",
    "configurationName": "Standard Employee Import",
    "type": "mechanical_work",
    "mappings": [
      {
        "csvColumn": "Employee Name",
        "modelField": "fullName"
      },
      {
        "csvColumn": "Position",
        "modelField": "designation"
      }
    ],
    "isDefault": false,
    "createdAt": "2024-04-06T10:30:00.000Z",
    "updatedAt": "2024-04-06T10:30:00.000Z"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "error": "fullName field mapping is required"
}
```

---

### 3. Get Saved Configurations

**Endpoint**: `GET /api/v1/manpower/field-mapping/save?type={type}`

**Description**: Retrieve all saved field mapping configurations for a specific type.

**Authentication**: Required

**Query Parameters**:
- `type` (required): `mechanical_work` or `insulation_work`

**cURL Example**:
```bash
curl -X GET 'http://localhost:3000/api/v1/manpower/field-mapping/save?type=mechanical_work' \
  -H 'Cookie: your-session-cookie'
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "_id": "64a1b2c3d4e5f6g7h8i9j0k1",
      "company": "64a1b2c3d4e5f6g7h8i9j0k2",
      "configurationName": "Standard Employee Import",
      "type": "mechanical_work",
      "mappings": [
        {
          "csvColumn": "Employee Name",
          "modelField": "fullName"
        },
        {
          "csvColumn": "Position",
          "modelField": "designation"
        }
      ],
      "isDefault": true,
      "createdAt": "2024-04-06T10:30:00.000Z",
      "updatedAt": "2024-04-06T10:30:00.000Z"
    },
    {
      "_id": "64a1b2c3d4e5f6g7h8i9j0k3",
      "configurationName": "Contractor Import",
      "type": "mechanical_work",
      "mappings": [
        {
          "csvColumn": "Name",
          "modelField": "fullName"
        },
        {
          "csvColumn": "Role",
          "modelField": "designation"
        }
      ],
      "isDefault": false,
      "createdAt": "2024-04-05T08:20:00.000Z",
      "updatedAt": "2024-04-05T08:20:00.000Z"
    }
  ]
}
```

---

### 4. Delete Configuration

**Endpoint**: `DELETE /api/v1/manpower/field-mapping/save?configId={configId}`

**Description**: Delete a saved field mapping configuration.

**Authentication**: Required

**Query Parameters**:
- `configId` (required): Configuration ID to delete

**cURL Example**:
```bash
curl -X DELETE 'http://localhost:3000/api/v1/manpower/field-mapping/save?configId=64a1b2c3d4e5f6g7h8i9j0k1' \
  -H 'Cookie: your-session-cookie'
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Configuration deleted successfully"
}
```

---

### 5. Import with Custom Mapping

**Endpoint**: `POST /api/v1/manpower/field-mapping/import`

**Description**: Import manpower data using custom field mappings.

**Authentication**: Required

**Query Parameters**:
- `type` (required): `mechanical_work` or `insulation_work`
- `siteId` (optional): Site ID to assign manpower to
- `configId` (optional): Use saved configuration ID
- `mappings` (optional): JSON string of custom mappings (if not using configId)

**Request**:
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: Form data with file

**cURL Example (Using Saved Config)**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/import?type=mechanical_work&configId=64a1b2c3d4e5f6g7h8i9j0k1&siteId=64a1b2c3d4e5f6g7h8i9j0k5' \
  -H 'Cookie: your-session-cookie' \
  -F 'file=@/path/to/manpower.xlsx'
```

**cURL Example (Using Custom Mappings)**:
```bash
# First, URL encode the mappings JSON
MAPPINGS='[{"csvColumn":"Employee Name","modelField":"fullName"},{"csvColumn":"Position","modelField":"designation"},{"csvColumn":"Phone","modelField":"phoneNumber"},{"csvColumn":"Salary","modelField":"salary"}]'

curl -X POST "http://localhost:3000/api/v1/manpower/field-mapping/import?type=mechanical_work&mappings=$(echo $MAPPINGS | jq -sRr @uri)" \
  -H 'Cookie: your-session-cookie' \
  -F 'file=@/path/to/manpower.xlsx'
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Manpower import completed",
  "data": {
    "totalRows": 50,
    "successCount": 45,
    "duplicatesFound": 3,
    "errorCount": 2,
    "errors": [
      {
        "row": 15,
        "error": "Full Name is required",
        "data": {
          "rowNumber": 15
        }
      },
      {
        "row": 32,
        "error": "Invalid Pay Basics: weekly. Must be one of: daily, monthly, yearly, fixed",
        "data": {
          "rowNumber": 32
        }
      }
    ],
    "createdManpower": [
      {
        "_id": "64a1b2c3d4e5f6g7h8i9j0k6",
        "fullName": "John Doe",
        "designation": "Supervisor",
        "phoneNumber": "9876543210",
        "salary": 50000,
        "payBasics": "monthly",
        "type": "mechanical_work",
        "company": "64a1b2c3d4e5f6g7h8i9j0k2"
      }
    ],
    "siteAssignments": [
      {
        "manpowerId": "64a1b2c3d4e5f6g7h8i9j0k6",
        "manpowerName": "John Doe",
        "siteId": "64a1b2c3d4e5f6g7h8i9j0k5",
        "action": "created_and_site_assigned"
      }
    ]
  },
  "summary": {
    "newManpower": 45,
    "duplicates": 3,
    "siteAssignments": 45,
    "errors": 2
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "error": "Required field 'fullName' must be mapped"
}
```

---

## Model Fields Reference

### Available Manpower Fields

| Field Name | Label | Type | Required | Enum Values | Description |
|------------|-------|------|----------|-------------|-------------|
| `fullName` | Full Name | string | ✅ Yes | - | Employee's full name |
| `designation` | Designation | string | No | - | Job title/position |
| `employeeCode` | Employee Code | string | No | - | Unique employee identifier |
| `phoneNumber` | Phone Number | string | No | - | Contact number |
| `aaddharNumber` | Aadhar Number | string | No | - | Aadhar card number |
| `panNumber` | PAN Number | string | No | - | PAN card number |
| `dateOfBirth` | Date of Birth | date | No | - | Birth date (DD/MM/YYYY or YYYY-MM-DD) |
| `dateOfJoining` | Date of Joining | date | No | - | Joining date (DD/MM/YYYY or YYYY-MM-DD) |
| `pfApplicable` | PF Applicable | boolean | No | - | Whether PF is applicable (yes/no/true/false) |
| `basicSalary` | Basic Salary | number | No | - | Basic salary amount |
| `hra` | HRA | number | No | - | House Rent Allowance |
| `da` | DA | number | No | - | Dearness Allowance |
| `specialAllowance` | Special Allowance | number | No | - | Special allowance amount |
| `travelAllowance` | Travel Allowance | number | No | - | Travel allowance amount |
| `medicalAllowance` | Medical Allowance | number | No | - | Medical allowance amount |
| `bankAccountNumber` | Bank Account Number | string | No | - | Bank account number |
| `ifscCode` | IFSC Code | string | No | - | Bank IFSC code |
| `epfNumber` | EPF Number | string | No | - | EPF number |
| `uanNumber` | UAN Number | string | No | - | Universal Account Number |
| `esicNumber` | ESIC Number | string | No | - | ESIC number |
| `payBasics` | Pay Basics | enum | No | daily, monthly, yearly, fixed | Payment frequency |
| `salary` | Salary | number | No | - | Total salary amount |
| `totalHour` | Total Hours | string | No | - | Working hours per day |
| `remarks` | Remarks | string | No | - | Additional notes |

---

## Frontend Implementation Guide

### React Component Integration

```tsx
import ManpowerFieldMapping from '@/components/ManpowerFieldMapping'

// In your dashboard or page component
function ManpowerPage() {
  const [siteType, setSiteType] = useState<'mechanical_work' | 'insulation_work'>('mechanical_work')
  
  return (
    <div>
      <ManpowerFieldMapping siteType={siteType} />
    </div>
  )
}
```

### Flutter Implementation

#### 1. Upload and Preview

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>> uploadAndPreview() async {
  // Pick file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls', 'csv'],
  );
  
  if (result == null) return {};
  
  File file = File(result.files.single.path!);
  
  // Create multipart request
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://your-api-url/api/v1/manpower/field-mapping/preview'),
  );
  
  // Add file
  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  
  // Add headers (session cookie or token)
  request.headers['Cookie'] = 'your-session-cookie';
  
  // Send request
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return jsonDecode(responseData);
}
```

#### 2. Save Configuration

```dart
Future<void> saveConfiguration(
  String configName,
  String type,
  List<Map<String, String>> mappings,
) async {
  final response = await http.post(
    Uri.parse('http://your-api-url/api/v1/manpower/field-mapping/save'),
    headers: {
      'Content-Type': 'application/json',
      'Cookie': 'your-session-cookie',
    },
    body: jsonEncode({
      'configurationName': configName,
      'type': type,
      'mappings': mappings,
      'isDefault': false,
    }),
  );
  
  if (response.statusCode == 200) {
    print('Configuration saved successfully');
  } else {
    throw Exception('Failed to save configuration');
  }
}
```

#### 3. Import with Mapping

```dart
Future<Map<String, dynamic>> importWithMapping(
  File file,
  String type,
  List<Map<String, String>> mappings,
  {String? siteId}
) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://your-api-url/api/v1/manpower/field-mapping/import'),
  );
  
  // Add query parameters
  var uri = Uri.parse('http://your-api-url/api/v1/manpower/field-mapping/import');
  uri = uri.replace(queryParameters: {
    'type': type,
    if (siteId != null) 'siteId': siteId,
    'mappings': jsonEncode(mappings),
  });
  
  request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  request.headers['Cookie'] = 'your-session-cookie';
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return jsonDecode(responseData);
}
```

#### 4. Complete Flutter UI Example

```dart
class ManpowerFieldMappingScreen extends StatefulWidget {
  final String siteType;
  
  const ManpowerFieldMappingScreen({required this.siteType});
  
  @override
  _ManpowerFieldMappingScreenState createState() => _ManpowerFieldMappingScreenState();
}

class _ManpowerFieldMappingScreenState extends State<ManpowerFieldMappingScreen> {
  int currentStep = 0;
  File? selectedFile;
  List<String> csvColumns = [];
  List<ModelField> modelFields = [];
  Map<String, String> fieldMappings = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Manpower')),
      body: Stepper(
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep == 0) {
            // Upload file
            _uploadFile();
          } else if (currentStep == 1) {
            // Import data
            _importData();
          }
        },
        steps: [
          Step(
            title: Text('Upload File'),
            content: _buildUploadStep(),
            isActive: currentStep >= 0,
          ),
          Step(
            title: Text('Map Fields'),
            content: _buildMappingStep(),
            isActive: currentStep >= 1,
          ),
          Step(
            title: Text('Import'),
            content: _buildImportStep(),
            isActive: currentStep >= 2,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUploadStep() {
    return ElevatedButton(
      onPressed: _pickFile,
      child: Text('Select Excel/CSV File'),
    );
  }
  
  Widget _buildMappingStep() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: csvColumns.length,
      itemBuilder: (context, index) {
        String csvColumn = csvColumns[index];
        return ListTile(
          title: Text(csvColumn),
          trailing: DropdownButton<String>(
            value: fieldMappings[csvColumn],
            hint: Text('Select field'),
            items: modelFields.map((field) {
              return DropdownMenuItem(
                value: field.name,
                child: Text(field.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  fieldMappings[csvColumn] = value;
                }
              });
            },
          ),
        );
      },
    );
  }
  
  Widget _buildImportStep() {
    return Text('Import completed!');
  }
  
  Future<void> _pickFile() async {
    // File picker implementation
  }
  
  Future<void> _uploadFile() async {
    // Upload and preview implementation
  }
  
  Future<void> _importData() async {
    // Import implementation
  }
}

class ModelField {
  final String name;
  final String label;
  final bool required;
  
  ModelField({required this.name, required this.label, required this.required});
}
```

---

## Testing Guide

### Test with cURL

1. **Preview File**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/preview' \
  -H 'Cookie: your-session-cookie' \
  -F 'file=@test-manpower.xlsx'
```

2. **Save Configuration**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/save' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: your-session-cookie' \
  -d '{
    "configurationName": "Test Config",
    "type": "mechanical_work",
    "mappings": [
      {"csvColumn": "Name", "modelField": "fullName"},
      {"csvColumn": "Job", "modelField": "designation"}
    ]
  }'
```

3. **Get Configurations**:
```bash
curl -X GET 'http://localhost:3000/api/v1/manpower/field-mapping/save?type=mechanical_work' \
  -H 'Cookie: your-session-cookie'
```

4. **Import Data**:
```bash
curl -X POST 'http://localhost:3000/api/v1/manpower/field-mapping/import?type=mechanical_work&mappings=%5B%7B%22csvColumn%22%3A%22Name%22%2C%22modelField%22%3A%22fullName%22%7D%5D' \
  -H 'Cookie: your-session-cookie' \
  -F 'file=@test-manpower.xlsx'
```

---

## Error Handling

### Common Errors

| Error Code | Error Message | Solution |
|------------|---------------|----------|
| 400 | Invalid file type | Upload .xlsx, .xls, or .csv file |
| 400 | fullName field mapping is required | Ensure fullName is mapped |
| 400 | Custom mappings are required | Provide mappings or configId |
| 404 | Configuration not found | Check configId is valid |
| 500 | Failed to analyze file | Check file format and content |

---

## Best Practices

1. **Always map fullName**: This is the only required field
2. **Save frequently used configurations**: Reuse mappings for similar imports
3. **Preview before importing**: Check the preview data to ensure mappings are correct
4. **Handle errors gracefully**: Display error messages to users for failed rows
5. **Use site assignment**: Assign manpower to sites during import when possible
6. **Validate data**: Ensure dates are in correct format, enums match allowed values

---

## Migration from Old System

If you're migrating from the old flexible upload system:

1. **Old API**: `/api/v1/manpower/flexible-upload?analyze=true`
2. **New API**: `/api/v1/manpower/field-mapping/preview`

The new system provides:
- ✅ User-controlled field mapping
- ✅ Saved configurations for reuse
- ✅ Better error handling
- ✅ Preview before import
- ✅ Confidence scores for suggestions

---

## Support

For issues or questions:
- Check error messages in API responses
- Verify field mappings include required fields
- Ensure file format is supported
- Contact backend team for assistance
