# Structure Work Module - API Documentation

## Overview
The Structure Work module allows users to manage Bill of Quantities (BOQ), Daily Progress Reports (DPR), and generate various sheets for structure work projects. This document provides a complete API reference for frontend implementation.

---

## Table of Contents
1. [Authentication](#authentication)
2. [Site Selection](#site-selection)
3. [BOQ Management](#boq-management)
4. [DPR Management](#dpr-management)
5. [Sheet Downloads](#sheet-downloads)
6. [Data Models](#data-models)
7. [User Flow](#user-flow)

---

## Authentication

All API endpoints require authentication. Include the authentication token in the request headers:

```
Authorization: Bearer <token>
```

---

## Site Selection

### Get All Sites
Fetch all sites for the company to allow users to select a site for structure work.

**Endpoint:** `GET /api/v1/sites`

**Query Parameters:**
- `companyId` (required): Company ID
- `type` (optional): Filter by site type

**Response:**
```json
[
  {
    "_id": "site123",
    "siteName": "Construction Site A",
    "address": "123 Main St",
    "contactPerson": "John Doe",
    "company": "company123",
    "type": "construction",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
]
```

---

## BOQ Management

### 1. Upload BOQ Excel File

Upload an Excel file containing Bill of Quantities for structure work.

**Endpoint:** `POST /api/v1/site/{siteId}/boq-structure/upload`

**Method:** POST (multipart/form-data)

**Path Parameters:**
- `siteId` (required): Site ID

**Request Body:**
- `file` (required): Excel file (.xlsx, .xls)

**Excel File Format:**
The Excel file should contain the following columns (case-insensitive):
- `assembly_mark` / `assemblymark` / `assembly mark` / `mark` / `assembly` / `item` / `description` / `member` / `member mark` (required)
- `quantity` / `qty` / `no.` / `no` / `nos` / `count` (required)
- `length` / `len` / `l` / `l(m)` / `L(m)` (optional)
- `width` / `wdth` / `w` / `w(m)` / `breadth` / `b` / `W(m)` (optional)
- `height` / `hght` / `h` / `h(m)` / `depth` / `d` / `H(m)` (optional)
- `net_weight_per_unit` / `netweightperunit` / `net weight per unit` / `net weight(kg) for one` / `weight` / `wt` / `unit weight` / `weight per unit` (optional)

**Response:**
```json
{
  "success": true,
  "message": "BOQ uploaded successfully",
  "data": {
    "_id": "boq123",
    "boqName": "Structure BOQ 2024",
    "boqNumber": "BOQ-STR-1704067200000",
    "siteId": "site123",
    "company": "company123",
    "type": "structure_work",
    "items": [
      {
        "_id": "item123",
        "assemblyMark": "C1",
        "quantity": 100,
        "availableQty": 100,
        "length": 5.5,
        "width": 2.0,
        "height": 3.0,
        "netWeightPerUnit": 150,
        "totalNetWeight": 15000,
        "usedQty": 0,
        "remainingQty": 100,
        "progressPercentage": 0
      }
    ],
    "totalQuantity": 100,
    "totalNetWeight": 15000,
    "totalItems": 1,
    "usedQuantity": 0,
    "remainingQuantity": 100,
    "progressPercentage": 0,
    "status": "active",
    "uploadMethod": "excel",
    "excelFileName": "structure_boq.xlsx",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

**cURL Example:**
```bash
curl -X POST \
  'https://your-domain.com/api/v1/site/site123/boq-structure/upload' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -F 'file=@/path/to/boq.xlsx'
```

---

### 2. Get All BOQs for a Site

Retrieve all uploaded BOQs for a specific site.

**Endpoint:** `GET /api/v1/site/{siteId}/boq-structure`

**Path Parameters:**
- `siteId` (required): Site ID

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "boq123",
      "boqName": "Structure BOQ 2024",
      "boqNumber": "BOQ-STR-1704067200000",
      "siteId": {
        "_id": "site123",
        "siteName": "Construction Site A"
      },
      "totalQuantity": 100,
      "totalNetWeight": 15000,
      "totalItems": 1,
      "usedQuantity": 20,
      "remainingQuantity": 80,
      "progressPercentage": 20,
      "status": "active",
      "uploadedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

**cURL Example:**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/boq-structure' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

---

### 3. Get Specific BOQ Details

Get detailed information about a specific BOQ including all items.

**Endpoint:** `GET /api/v1/site/{siteId}/boq-structure/{boqId}`

**Path Parameters:**
- `siteId` (required): Site ID
- `boqId` (required): BOQ ID

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "boq123",
    "boqName": "Structure BOQ 2024",
    "boqNumber": "BOQ-STR-1704067200000",
    "siteId": {
      "_id": "site123",
      "siteName": "Construction Site A"
    },
    "items": [
      {
        "_id": "item123",
        "assemblyMark": "C1",
        "quantity": 100,
        "availableQty": 80,
        "length": 5.5,
        "width": 2.0,
        "height": 3.0,
        "netWeightPerUnit": 150,
        "totalNetWeight": 15000,
        "usedQty": 20,
        "remainingQty": 80,
        "progressPercentage": 20
      }
    ],
    "totalQuantity": 100,
    "totalNetWeight": 15000,
    "totalItems": 1,
    "usedQuantity": 20,
    "remainingQuantity": 80,
    "progressPercentage": 20,
    "status": "active"
  }
}
```

**cURL Example:**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/boq-structure/boq123' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

---

### 4. Get BOQ Items

Get only the items from a specific BOQ (useful for creating DPR entries).

**Endpoint:** `GET /api/v1/site/{siteId}/boq-structure/{boqId}/items`

**Path Parameters:**
- `siteId` (required): Site ID
- `boqId` (required): BOQ ID

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "boq123",
    "boqName": "Structure BOQ 2024",
    "items": [
      {
        "_id": "item123",
        "assemblyMark": "C1",
        "quantity": 100,
        "availableQty": 80,
        "netWeightPerUnit": 150,
        "usedQty": 20,
        "remainingQty": 80
      }
    ]
  }
}
```

---

## DPR Management

### 1. Create DPR Entry

Create a new Daily Progress Report entry for structure work.

**Endpoint:** `POST /api/v1/site/{siteId}/dpr-structure`

**Path Parameters:**
- `siteId` (required): Site ID

**Request Body:**
```json
{
  "boqId": "boq123",
  "items": [
    {
      "assemblyMark": "C1",
      "qtyUsed": 10,
      "boqItemId": "item123"
    },
    {
      "assemblyMark": "C2",
      "qtyUsed": 5,
      "boqItemId": "item124"
    }
  ],
  "date": "2024-01-15T00:00:00.000Z",
  "remarks": "Good progress today",
  "teamId": "team123"
}
```

**Field Descriptions:**
- `boqId` (required): BOQ ID from which items are being used
- `items` (required): Array of items with quantities used
  - `assemblyMark` (required): Assembly mark identifier
  - `qtyUsed` (required): Quantity used in this DPR
  - `boqItemId` (required): Reference to the BOQ item ID
- `date` (optional): DPR date (defaults to current IST date)
- `remarks` (optional): Any remarks or notes
- `teamId` (optional): Team ID if tracking by team

**Response:**
```json
{
  "success": true,
  "message": "DPR entry created successfully",
  "data": {
    "_id": "dpr123",
    "dprName": "Structure DPR - 15/01/2024",
    "dprNumber": "DPR-STR-1705276800000",
    "siteId": "site123",
    "company": "company123",
    "boqId": "boq123",
    "type": "structure_work",
    "items": [
      {
        "_id": "dprItem123",
        "assemblyMark": "C1",
        "qtyUsed": 10,
        "netWeightPerUnit": 150,
        "totalNetWeight": 1500,
        "boqItemId": "item123"
      }
    ],
    "totalQtyUsed": 15,
    "totalNetWeight": 2250,
    "date": "2024-01-15T00:00:00.000Z",
    "status": "submitted",
    "remarks": "Good progress today",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Validation:**
- Quantity used cannot exceed available quantity in BOQ
- All items must exist in the referenced BOQ
- BOQ must belong to the specified site

**cURL Example:**
```bash
curl -X POST \
  'https://your-domain.com/api/v1/site/site123/dpr-structure' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "boqId": "boq123",
    "items": [
      {
        "assemblyMark": "C1",
        "qtyUsed": 10,
        "boqItemId": "item123"
      }
    ],
    "remarks": "Good progress today"
  }'
```

---

### 2. Get DPR Entries

Retrieve DPR entries with optional filters.

**Endpoint:** `GET /api/v1/site/{siteId}/dpr-structure`

**Path Parameters:**
- `siteId` (required): Site ID

**Query Parameters:**
- `startDate` (optional): Filter DPRs from this date (ISO format)
- `endDate` (optional): Filter DPRs until this date (ISO format)
- `boqId` (optional): Filter by specific BOQ

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "dpr123",
      "dprName": "Structure DPR - 15/01/2024",
      "dprNumber": "DPR-STR-1705276800000",
      "siteId": {
        "_id": "site123",
        "siteName": "Construction Site A"
      },
      "boqId": {
        "_id": "boq123",
        "boqName": "Structure BOQ 2024",
        "boqNumber": "BOQ-STR-1704067200000"
      },
      "teamId": {
        "_id": "team123",
        "teamName": "Team A"
      },
      "items": [
        {
          "assemblyMark": "C1",
          "qtyUsed": 10,
          "netWeightPerUnit": 150,
          "totalNetWeight": 1500
        }
      ],
      "totalQtyUsed": 10,
      "totalNetWeight": 1500,
      "date": "2024-01-15T00:00:00.000Z",
      "status": "submitted",
      "remarks": "Good progress today",
      "createdBy": {
        "_id": "user123",
        "fullName": "John Doe",
        "email": "john@example.com"
      },
      "createdAt": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

**cURL Example:**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/dpr-structure?startDate=2024-01-01&endDate=2024-01-31&boqId=boq123' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

---

### 3. Get Specific DPR Details

Get detailed information about a specific DPR entry.

**Endpoint:** `GET /api/v1/site/{siteId}/dpr-structure/{dprId}`

**Path Parameters:**
- `siteId` (required): Site ID
- `dprId` (required): DPR ID

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "dpr123",
    "dprName": "Structure DPR - 15/01/2024",
    "dprNumber": "DPR-STR-1705276800000",
    "siteId": {
      "_id": "site123",
      "siteName": "Construction Site A"
    },
    "boqId": {
      "_id": "boq123",
      "boqName": "Structure BOQ 2024"
    },
    "items": [
      {
        "_id": "dprItem123",
        "assemblyMark": "C1",
        "qtyUsed": 10,
        "netWeightPerUnit": 150,
        "totalNetWeight": 1500,
        "boqItemId": "item123",
        "length": 5.5,
        "width": 2.0,
        "height": 3.0,
        "availableQty": 70,
        "remainingQty": 70
      }
    ],
    "totalQtyUsed": 10,
    "totalNetWeight": 1500,
    "date": "2024-01-15T00:00:00.000Z",
    "status": "submitted",
    "remarks": "Good progress today",
    "createdBy": {
      "_id": "user123",
      "fullName": "John Doe"
    }
  }
}
```

**cURL Example:**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/dpr-structure/dpr123' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

---

### 4. Update DPR Entry

Update an existing DPR entry.

**Endpoint:** `PUT /api/v1/site/{siteId}/dpr-structure/{dprId}`

**Path Parameters:**
- `siteId` (required): Site ID
- `dprId` (required): DPR ID

**Request Body:**
```json
{
  "items": [
    {
      "assemblyMark": "C1",
      "qtyUsed": 15,
      "boqItemId": "item123"
    }
  ],
  "remarks": "Updated progress notes",
  "status": "approved"
}
```

**Field Descriptions:**
- `items` (optional): Updated items array
- `remarks` (optional): Updated remarks
- `status` (optional): Status update ("draft", "submitted", "approved", "rejected")

**Response:**
```json
{
  "success": true,
  "message": "DPR updated successfully",
  "data": {
    "_id": "dpr123",
    "dprName": "Structure DPR - 15/01/2024",
    "items": [...],
    "totalQtyUsed": 15,
    "totalNetWeight": 2250,
    "status": "approved",
    "remarks": "Updated progress notes",
    "updatedBy": "user123",
    "updatedDate": "2024-01-16T00:00:00.000Z"
  }
}
```

**Note:** When updating items, the system will:
1. Restore quantities to BOQ from old items
2. Deduct new quantities from BOQ
3. Validate that new quantities don't exceed available quantities

**cURL Example:**
```bash
curl -X PUT \
  'https://your-domain.com/api/v1/site/site123/dpr-structure/dpr123' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "remarks": "Updated progress notes",
    "status": "approved"
  }'
```

---

### 5. Delete DPR Entry

Delete a DPR entry and restore quantities to BOQ.

**Endpoint:** `DELETE /api/v1/site/{siteId}/dpr-structure/{dprId}`

**Path Parameters:**
- `siteId` (required): Site ID
- `dprId` (required): DPR ID

**Response:**
```json
{
  "success": true,
  "message": "DPR deleted successfully"
}
```

**Note:** Deleting a DPR will automatically restore the used quantities back to the BOQ's available quantities.

**cURL Example:**
```bash
curl -X DELETE \
  'https://your-domain.com/api/v1/site/site123/dpr-structure/dpr123' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

---

## Sheet Downloads

### Download Sheets (Measurement, Abstract, Summary, Detailed DPR)

Generate and download various types of sheets in PDF or Excel format.

**Endpoint:** `GET /api/v1/site/{siteId}/structure-work/sheets`

**Path Parameters:**
- `siteId` (required): Site ID

**Query Parameters:**
- `fromDate` (required): Start date for the report (format: YYYY-MM-DD)
- `toDate` (required): End date for the report (format: YYYY-MM-DD)
- `sheetType` (required): Type of sheet - one of:
  - `measurement` - Detailed measurement records for all work items
  - `abstract` - Summarized abstract of all work with calculations
  - `summary` - High-level summary of work done with totals
  - `detailed` - Detailed DPR sheet (day-wise breakdown) - **Excel only**
- `format` (required): Output format - `pdf` or `excel`

**Response:**
Binary file download (PDF or Excel)

**Response Headers:**
```
Content-Type: application/pdf (for PDF) or application/vnd.openxmlformats-officedocument.spreadsheetml.sheet (for Excel)
Content-Disposition: attachment; filename="Structure_Measurement_2024-01-01_to_2024-01-31.pdf"
Content-Length: <file_size>
```

**Sheet Type Details:**

#### 1. Measurement Sheet
Contains detailed measurement records with:
- Serial number
- Date
- Work description
- Assembly mark
- Quantity used
- Dimensions (Length, Width, Height)
- Weight
- UOM (Unit of Measurement)

**Available Formats:** PDF, Excel

#### 2. Abstract Sheet
Contains summarized data with:
- Description
- Total quantity
- Total weight
- UOM

**Available Formats:** PDF, Excel

#### 3. Summary Sheet
Contains high-level summary with:
- Total DPR entries
- Total assembly items
- Total quantity used
- Total weight
- Work type
- Period from/to

**Available Formats:** PDF, Excel

#### 4. Detailed DPR Sheet
Contains day-wise breakdown with:
- Company header
- Site information
- Week-wise structure (W-1, W-2, etc.)
- Daily columns (Plan and Actual)
- Scope data (Sr No, Area, Activity Description, UOM, Scope, Completed, Balance, etc.)
- Daily totals
- Weekly totals
- Monthly totals

**Available Formats:** Excel only (PDF not supported)

**Error Responses:**

```json
{
  "success": false,
  "message": "Missing required parameters: fromDate, toDate, sheetType"
}
```

```json
{
  "success": false,
  "message": "Invalid sheet type. Must be one of: measurement, abstract, summary, detailed"
}
```

```json
{
  "success": false,
  "message": "Detailed DPR sheet only supports Excel format"
}
```

```json
{
  "success": false,
  "message": "No Structure Work DPR data found for the specified criteria"
}
```

**cURL Examples:**

**Measurement Sheet (PDF):**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/structure-work/sheets?fromDate=2024-01-01&toDate=2024-01-31&sheetType=measurement&format=pdf' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  --output measurement_sheet.pdf
```

**Abstract Sheet (Excel):**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/structure-work/sheets?fromDate=2024-01-01&toDate=2024-01-31&sheetType=abstract&format=excel' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  --output abstract_sheet.xlsx
```

**Summary Sheet (PDF):**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/structure-work/sheets?fromDate=2024-01-01&toDate=2024-01-31&sheetType=summary&format=pdf' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  --output summary_sheet.pdf
```

**Detailed DPR (Excel only):**
```bash
curl -X GET \
  'https://your-domain.com/api/v1/site/site123/structure-work/sheets?fromDate=2024-01-01&toDate=2024-01-31&sheetType=detailed&format=excel' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  --output detailed_dpr.xlsx
```

**JavaScript/Fetch Example:**
```javascript
const downloadSheet = async (siteId, fromDate, toDate, sheetType, format) => {
  const url = `/api/v1/site/${siteId}/structure-work/sheets?fromDate=${fromDate}&toDate=${toDate}&sheetType=${sheetType}&format=${format}`;
  
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }
  
  const blob = await response.blob();
  const downloadUrl = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = downloadUrl;
  link.download = `Structure_${sheetType}_${fromDate}_to_${toDate}.${format === 'pdf' ? 'pdf' : 'xlsx'}`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(downloadUrl);
};

// Usage
downloadSheet('site123', '2024-01-01', '2024-01-31', 'measurement', 'pdf');
```

---

## Data Models

### BOQ Structure Item
```typescript
interface BOQStructureItem {
  _id: string;
  assemblyMark: string;           // Assembly mark identifier
  quantity: number;                // Total quantity in BOQ
  availableQty: number;            // Available quantity (not yet used)
  length: number;                  // Length in meters
  width: number;                   // Width in meters
  height: number;                  // Height in meters
  netWeightPerUnit: number;        // Weight per unit in kg
  totalNetWeight: number;          // Total weight (quantity * netWeightPerUnit)
  usedQty: number;                 // Quantity already used in DPRs
  remainingQty: number;            // Remaining quantity (availableQty - usedQty)
  progressPercentage: number;      // Progress percentage
}
```

### BOQ Structure
```typescript
interface BOQStructure {
  _id: string;
  boqName: string;                 // BOQ name
  boqNumber: string;               // Unique BOQ number (BOQ-STR-timestamp)
  siteId: string | Site;           // Reference to site
  company: string;                 // Reference to company
  type: 'structure_work';          // Always structure_work
  items: BOQStructureItem[];       // Array of BOQ items
  totalQuantity: number;           // Sum of all item quantities
  totalNetWeight: number;          // Sum of all item weights
  totalItems: number;              // Count of items
  usedQuantity: number;            // Total quantity used across all items
  remainingQuantity: number;       // Total remaining quantity
  progressPercentage: number;      // Overall progress percentage
  varianceQuantity: number;        // Variance in quantity
  varianceStatus: 'on_track' | 'under' | 'over' | 'not_started';
  status: 'draft' | 'active' | 'completed';
  uploadMethod: 'excel' | 'manual';
  excelFileName?: string;          // Original Excel filename
  uploadedAt: Date;
  createdBy: string;               // User who created
  createdAt: Date;
  updatedAt: Date;
}
```

### DPR Structure Item
```typescript
interface DPRStructureItem {
  _id: string;
  assemblyMark: string;            // Assembly mark identifier
  qtyUsed: number;                 // Quantity used in this DPR
  netWeightPerUnit: number;        // Weight per unit in kg
  totalNetWeight: number;          // Total weight for this item
  boqItemId: string;               // Reference to BOQ item
}
```

### DPR Structure
```typescript
interface DPRStructure {
  _id: string;
  dprName: string;                 // DPR name
  dprNumber: string;               // Unique DPR number (DPR-STR-timestamp)
  siteId: string | Site;           // Reference to site
  company: string;                 // Reference to company
  teamId?: string | Team;          // Reference to team (optional)
  boqId: string | BOQStructure;    // Reference to BOQ
  type: 'structure_work';          // Always structure_work
  items: DPRStructureItem[];       // Array of DPR items
  totalQtyUsed: number;            // Sum of quantities used
  totalNetWeight: number;          // Sum of weights
  date: Date;                      // DPR date (IST)
  updatedDate?: Date;              // Last update date
  status: 'draft' | 'submitted' | 'approved' | 'rejected';
  remarks?: string;                // Optional remarks
  createdBy: string | User;        // User who created
  updatedBy?: string | User;       // User who last updated
  approvedBy?: string | User;      // User who approved
  createdAt: Date;
  updatedAt: Date;
}
```

---

## User Flow

### Complete Implementation Flow

#### 1. Site Selection Flow
```
User lands on Structure Work page
  ↓
Fetch all sites: GET /api/v1/admin/sites?companyId={companyId}
  ↓
User selects a site from dropdown
  ↓
Store selected siteId in state
```

#### 2. BOQ Tab Flow
```
User clicks on "BOQ" tab
  ↓
Fetch all BOQs: GET /api/v1/site/{siteId}/boq-structure
  ↓
Display list of uploaded BOQs with:
  - BOQ Name
  - BOQ Number
  - Total Items
  - Total Quantity
  - Used Quantity
  - Remaining Quantity
  - Progress Percentage
  - Upload Date
  ↓
User can:
  a) Upload new BOQ:
     - Click "Upload BOQ" button
     - Select Excel file
     - POST /api/v1/site/{siteId}/boq-structure/upload
     - Show success message
     - Refresh BOQ list
  
  b) View BOQ details:
     - Click on a BOQ row
     - GET /api/v1/site/{siteId}/boq-structure/{boqId}
     - Show modal/page with all items
     - Display: Assembly Mark, Quantity, Available Qty, Used Qty, 
       Remaining Qty, Dimensions, Weight, Progress
```

#### 3. DPR Tab Flow
```
User clicks on "DPR" tab
  ↓
Fetch DPR entries: GET /api/v1/site/{siteId}/dpr-structure
  ↓
Display list of DPR entries with:
  - DPR Name
  - DPR Number
  - BOQ Name
  - Date
  - Total Qty Used
  - Total Weight
  - Status
  - Created By
  ↓
User can:
  a) Create new DPR:
     - Click "Create DPR" button
     - Show form with:
       * Select BOQ dropdown (fetch from BOQ list)
       * Date picker (defaults to today)
       * Team selector (optional)
       * Items section:
         - Fetch BOQ items: GET /api/v1/site/{siteId}/boq-structure/{boqId}/items
         - Show available items with remaining quantities
         - User selects items and enters quantities used
         - Validate: qtyUsed <= availableQty
       * Remarks textarea
     - Submit: POST /api/v1/site/{siteId}/dpr-structure
     - Show success message
     - Refresh DPR list
     - Update BOQ quantities automatically
  
  b) View DPR details:
     - Click on DPR row
     - GET /api/v1/site/{siteId}/dpr-structure/{dprId}
     - Show modal/page with all details
  
  c) Edit DPR:
     - Click "Edit" button on DPR
     - Load existing data
     - Allow modifications
     - PUT /api/v1/site/{siteId}/dpr-structure/{dprId}
     - Refresh list
  
  d) Delete DPR:
     - Click "Delete" button
     - Show confirmation dialog
     - DELETE /api/v1/site/{siteId}/dpr-structure/{dprId}
     - Refresh list
     - BOQ quantities restored automatically
  
  e) Filter DPRs:
     - Date range filter
     - BOQ filter
     - Apply filters and refetch with query params
```

#### 4. Sheets Tab Flow
```
User clicks on "Sheets" tab
  ↓
Show download options form:
  - Date Range Picker (From Date, To Date)
  - Sheet Type Selector:
    * Measurement Sheet
    * Abstract Sheet
    * Summary Sheet
    * Detailed DPR
  - Format Selector:
    * PDF (disabled for Detailed DPR)
    * Excel
  ↓
User selects options and clicks "Download"
  ↓
Validate:
  - Date range selected
  - Sheet type selected
  - Format selected
  - If Detailed DPR, format must be Excel
  ↓
Download sheet:
  GET /api/v1/site/{siteId}/structure-work/sheets?
    fromDate={fromDate}&
    toDate={toDate}&
    sheetType={sheetType}&
    format={format}
  ↓
Handle response:
  - Success: Download file with proper filename
  - Error: Show error message
```

### State Management Recommendations

```typescript
// Main state structure
interface StructureWorkState {
  selectedSite: Site | null;
  boqs: BOQStructure[];
  selectedBoq: BOQStructure | null;
  dprs: DPRStructure[];
  selectedDpr: DPRStructure | null;
  loading: {
    sites: boolean;
    boqs: boolean;
    dprs: boolean;
    sheets: boolean;
  };
  filters: {
    dprStartDate: string | null;
    dprEndDate: string | null;
    dprBoqId: string | null;
  };
  sheetDownload: {
    fromDate: string;
    toDate: string;
    sheetType: 'measurement' | 'abstract' | 'summary' | 'detailed';
    format: 'pdf' | 'excel';
  };
}
```

### Error Handling

All API endpoints return errors in the following format:

```json
{
  "success": false,
  "message": "Error description"
}
```

Common error scenarios:
- **400 Bad Request**: Missing required parameters, invalid data
- **401 Unauthorized**: Invalid or missing authentication token
- **403 Forbidden**: User doesn't have permission
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server-side error

Handle errors gracefully in the UI with appropriate user messages.

---

## Frontend Implementation Checklist

### BOQ Tab
- [ ] Upload BOQ button with file input
- [ ] BOQ list table/cards with pagination
- [ ] BOQ details modal/page
- [ ] Progress indicators for each BOQ
- [ ] Refresh functionality
- [ ] Loading states
- [ ] Error handling

### DPR Tab
- [ ] Create DPR button and form
- [ ] DPR list table/cards with pagination
- [ ] DPR details modal/page
- [ ] Edit DPR functionality
- [ ] Delete DPR with confirmation
- [ ] Date range filter
- [ ] BOQ filter
- [ ] Status badges
- [ ] Loading states
- [ ] Error handling
- [ ] Quantity validation in forms

### Sheets Tab
- [ ] Date range picker
- [ ] Sheet type selector
- [ ] Format selector (disable PDF for Detailed DPR)
- [ ] Download button
- [ ] Loading indicator during download
- [ ] Error handling
- [ ] Success notification

### General
- [ ] Site selector dropdown
- [ ] Tab navigation
- [ ] Responsive design
- [ ] Authentication handling
- [ ] API error handling
- [ ] Loading states
- [ ] Success/error notifications
- [ ] Data refresh mechanisms

---

## Notes

1. **Date Handling**: All dates are stored and processed in IST (Indian Standard Time). The backend automatically handles timezone conversion.

2. **Quantity Management**: The system automatically manages BOQ quantities:
   - When a DPR is created, quantities are deducted from BOQ
   - When a DPR is updated, old quantities are restored and new ones are deducted
   - When a DPR is deleted, quantities are restored to BOQ

3. **File Upload**: Use `multipart/form-data` for BOQ Excel upload. The backend supports various column name variations for flexibility.

4. **Sheet Downloads**: For sheet downloads, handle the binary response properly and create a download link. The `detailed` sheet type only supports Excel format.

5. **Validation**: Always validate user input on the frontend before making API calls to provide immediate feedback.

6. **Pagination**: Consider implementing pagination for BOQ and DPR lists if dealing with large datasets.

7. **Real-time Updates**: Consider implementing polling or WebSocket connections if real-time updates are needed when multiple users are working simultaneously.

---

## Support

For any issues or questions regarding the API implementation, please contact the backend development team.

**Last Updated:** January 2025
**API Version:** v1
