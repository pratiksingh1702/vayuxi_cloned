# PEB Work Type API Documentation - cURL Requests

**Document Version:** 1.0  
**Date:** May 9, 2026  
**Prepared For:** Frontend Developers  
**System:** BE-VAYUXI

---

## Table of Contents

1. [Authentication](#authentication)
2. [Work Type Constants](#work-type-constants)
3. [Work Type Configuration](#work-type-configuration)
4. [Site Creation](#site-creation)
5. [Rate Upload](#rate-upload)
6. [Procurement](#procurement)
7. [Inventory](#inventory)
8. [BOQ Upload](#boq-upload)
9. [DPR Setup](#dpr-setup)
10. [DPR Entry](#dpr-entry)
11. [Dispatch](#dispatch)
12. [Handover](#handover)
13. [Attendance](#attendance)

---

## Authentication

All API requests require authentication. Use the following headers:

```bash
# Headers to include in all requests
-H "Content-Type: application/json"
-H "Cookie: session=<your-session-cookie>"
```

Or for token-based authentication:

```bash
-H "Authorization: Bearer <your-token>"
```

---

## Work Type Constants

```typescript
// Available work types
const WORK_TYPES = {
  CIVIL: 'civil',
  ERECTION: 'erection',
  ROOFING: 'roofing',
  FABRICATION: 'fabrication',
  MECHANICAL: 'mechanical',
  INSULATION: 'insulation',
  STRUCTURE: 'structure',
  PEB: 'peb'
}
```

---

## Work Type Configuration

### 1. Create Work Type Configuration

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/work-type-config \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workTypes": {
      "civil": {
        "enabled": true,
        "sequence": 1
      },
      "erection": {
        "enabled": true,
        "sequence": 2
      },
      "roofing": {
        "enabled": true,
        "sequence": 3
      },
      "fabrication": {
        "enabled": true,
        "sequence": 4,
        "boqEnabled": true
      },
      "mechanical": {
        "enabled": true,
        "sequence": 5
      },
      "insulation": {
        "enabled": true,
        "sequence": 6
      },
      "structure": {
        "enabled": true,
        "sequence": 7
      },
      "peb": {
        "enabled": true,
        "sequence": 8
      }
    }
  }'
```

### 2. Get Work Type Configuration

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/work-type-config \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Update Work Type Configuration

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/work-type-config \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workTypes": {
      "civil": {
        "enabled": true,
        "sequence": 1
      },
      "fabrication": {
        "enabled": true,
        "sequence": 4,
        "boqEnabled": true
      }
    }
  }'
```

---

## Site Creation

### 1. Create Site with Work Types

```bash
curl -X POST http://localhost:3000/api/v1/site \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "siteName": "Project Alpha",
    "type": "peb_work",
    "address": "123 Industrial Area",
    "contactPerson": "John Doe",
    "phoneNumber": "9876543210",
    "email": "john@example.com",
    "workTypes": ["civil", "erection", "roofing", "fabrication", "mechanical", "insulation", "structure", "peb"]
  }'
```

### 2. Get Site Details

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Update Site Work Types

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workTypes": ["civil", "erection", "roofing", "fabrication"]
  }'
```

---

## Rate Upload

### 1. Upload Rate for Specific Work Type

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/rate-upload \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "fileName": "civil_rates.xlsx",
    "fileUrl": "https://example.com/civil_rates.xlsx",
    "fileSize": 102400,
    "fileType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "specification": "Grade M20",
        "unit": "m³",
        "rate": 5000,
        "moc": "Cement",
        "size": "Standard",
        "thickness": "N/A",
        "floor": "Ground"
      }
    ]
  }'
```

### 2. Get Rate Uploads by Work Type

```bash
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/rate-upload?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get All Rate Uploads

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/rate-upload \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Get Rate Upload by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/rate-upload/{rateUploadId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 5. Update Rate Upload

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/rate-upload/{rateUploadId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "specification": "Grade M20",
        "unit": "m³",
        "rate": 5500
      }
    ]
  }'
```

### 6. Delete Rate Upload

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/rate-upload/{rateUploadId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

---

## Procurement

### Procurement Requests

#### 1. Create Material Request

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/procurement/requests \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "requestNumber": "REQ-2026-001",
    "workType": "civil",
    "priority": "high",
    "expectedDeliveryDate": "2026-06-01",
    "remarks": "Urgent requirement for foundation work",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "specification": "Grade M20",
        "quantity": 100,
        "unit": "m³",
        "remarks": "Foundation concrete"
      },
      {
        "itemCode": "C002",
        "itemName": "Steel Bars",
        "specification": "TMT 12mm",
        "quantity": 5000,
        "unit": "kg",
        "remarks": "Reinforcement"
      }
    ]
  }'
```

#### 2. Get Material Requests

```bash
# Get all requests
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/requests \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get requests by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/requests?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get requests by status
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/requests?status=pending" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 3. Get Material Request by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/requests/{requestId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 4. Update Material Request

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/procurement/requests/{requestId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "priority": "medium",
    "expectedDeliveryDate": "2026-06-05",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "quantity": 150,
        "unit": "m³"
      }
    ]
  }'
```

#### 5. Delete Material Request

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/procurement/requests/{requestId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 6. Approve Material Request

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/procurement/requests/{requestId}/approve \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "comments": "Approved for procurement"
  }'
```

### Procurement Vendors

#### 1. Create Vendor

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/procurement/vendors \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "vendorName": "ABC Construction Supplies",
    "vendorCode": "V-001",
    "contactPerson": "Rajesh Kumar",
    "phoneNumber": "9876543211",
    "email": "rajesh@abcconstruction.com",
    "address": "456 Supplier Street, Industrial Area",
    "materials": ["Concrete", "Steel", "Cement"],
    "workTypes": ["civil", "erection", "roofing"],
    "rating": 4.5,
    "status": "active"
  }'
```

#### 2. Get Vendors

```bash
# Get all vendors
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/vendors \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get vendors by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/vendors?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get vendors by material
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/vendors?material=Concrete" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 3. Get Vendor by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/vendors/{vendorId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 4. Update Vendor

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/procurement/vendors/{vendorId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "rating": 4.8,
    "status": "active",
    "materials": ["Concrete", "Steel", "Cement", "Bricks"]
  }'
```

#### 5. Delete Vendor

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/procurement/vendors/{vendorId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### Procurement Purchase Orders

#### 1. Create Purchase Order

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "poNumber": "PO-2026-001",
    "workType": "civil",
    "vendorId": "{vendorId}",
    "requestId": "{requestId}",
    "orderDate": "2026-05-10",
    "expectedDeliveryDate": "2026-06-01",
    "remarks": "Purchase order for foundation materials",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "specification": "Grade M20",
        "quantity": 100,
        "unit": "m³",
        "rate": 5000,
        "amount": 500000
      },
      {
        "itemCode": "C002",
        "itemName": "Steel Bars",
        "specification": "TMT 12mm",
        "quantity": 5000,
        "unit": "kg",
        "rate": 50,
        "amount": 250000
      }
    ],
    "totalAmount": 750000
  }'
```

#### 2. Get Purchase Orders

```bash
# Get all purchase orders
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get purchase orders by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get purchase orders by vendor
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders?vendorId={vendorId}" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get purchase orders by status
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders?status=pending" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 3. Get Purchase Order by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders/{poId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 4. Update Purchase Order

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders/{poId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "expectedDeliveryDate": "2026-06-05",
    "items": [
      {
        "itemCode": "C001",
        "quantity": 120,
        "unit": "m³",
        "rate": 5200,
        "amount": 624000
      }
    ],
    "totalAmount": 874000
  }'
```

#### 5. Delete Purchase Order

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders/{poId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 6. Approve Purchase Order

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/procurement/purchase-orders/{poId}/approve \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "comments": "Approved for procurement"
  }'
```

### Procurement Approvals

#### 1. Get Approvals

```bash
# Get all approvals
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/approvals \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get approvals by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/approvals?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get pending approvals
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/procurement/approvals?status=pending" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 2. Get Approval by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/procurement/approvals/{approvalId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

#### 3. Update Approval

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/procurement/approvals/{approvalId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "status": "approved",
    "comments": "Approved for processing"
  }'
```

---

## Inventory

### 1. Create Inventory Item

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-inventory \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "materialName": "Concrete M20",
    "materialCode": "C001",
    "materialGrade": "Grade M20",
    "materialType": "construction",
    "workType": "civil",
    "moc": "Cement",
    "size": "Standard",
    "thickness": "N/A",
    "currentStock": 0,
    "currentWeight": 0,
    "uom": "m³",
    "supplier": "ABC Construction Supplies"
  }'
```

### 2. Get Inventory Items

```bash
# Get all inventory items
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-inventory \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get inventory by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-inventory?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get inventory by material type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-inventory?materialType=construction" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get Inventory Item by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Update Inventory Item

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "currentStock": 100,
    "currentWeight": 240000,
    "supplier": "XYZ Construction Supplies"
  }'
```

### 5. Delete Inventory Item

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 6. Add Inventory Movement

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId}/movement \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "movementType": "purchase_in",
    "quantity": 100,
    "weight": 240000,
    "uom": "m³",
    "referenceType": "purchase_order",
    "referenceId": "{poId}",
    "referenceNumber": "PO-2026-001",
    "projectName": "Project Alpha",
    "remarks": "Material received from purchase order"
  }'
```

### 7. Reserve Stock

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId}/reserve \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "projectId": "{projectId}",
    "projectName": "Project Alpha - Civil Work",
    "reservedQuantity": 50,
    "reservedWeight": 120000,
    "expectedConsumptionDate": "2026-06-15",
    "remarks": "Reserved for foundation work"
  }'
```

### 8. Consume Reserved Stock

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-inventory/{inventoryId}/consume \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "reservationId": "{reservationId}",
    "consumedQuantity": 30,
    "consumedWeight": 72000,
    "remarks": "Consumed for foundation casting"
  }'
```

---

## BOQ Upload

### 1. Upload BOQ (Fabrication Only)

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/boq-structure/upload \
  -H "Content-Type: multipart/form-data" \
  -H "Cookie: session=<your-session-cookie>" \
  -F "workType=fabrication" \
  -F "file=@/path/to/boq_file.xlsx" \
  -F "fileName=fabrication_boq.xlsx" \
  -F "remarks=Fabrication BOQ for Project Alpha"
```

### 2. Get BOQ List

```bash
# Get all BOQs
curl -X GET http://localhost:3000/api/v1/site/{siteId}/boq-structure \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get BOQs by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/boq-structure?workType=fabrication" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get BOQ by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/boq-structure/{boqId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Get Assembly Marks from BOQ

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/boq/{boqId}/assembly-marks \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 5. Get BOQ Items

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/boq-structure/{boqId}/items \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

---

## DPR Setup

### 1. Create DPR Setup

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "setupName": "Civil Work DPR Setup",
    "section": "civil",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Foundation Excavation",
        "description": "Excavation for foundation",
        "unit": "m³",
        "targetQuantity": 500,
        "uom": "m³",
        "moc": "Soil",
        "floor": "Ground",
        "size": "Standard",
        "thickness": "N/A",
        "remarks": "Foundation excavation work",
        "images": []
      },
      {
        "itemCode": "C002",
        "itemName": "Concrete Casting",
        "description": "Concrete casting for foundation",
        "unit": "m³",
        "targetQuantity": 300,
        "uom": "m³",
        "moc": "Concrete M20",
        "floor": "Ground",
        "size": "Standard",
        "thickness": "N/A",
        "remarks": "Foundation concrete work",
        "images": []
      }
    ]
  }'
```

### 2. Get DPR Setup

```bash
# Get all DPR setups
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get DPR setup by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get DPR setup by section
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup?section=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get DPR Setup by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup/{setupId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Update DPR Setup

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup/{setupId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "setupName": "Civil Work DPR Setup - Updated",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Foundation Excavation",
        "targetQuantity": 600
      }
    ]
  }'
```

### 5. Delete DPR Setup

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/peb-dpr-setup/{setupId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

---

## DPR Entry

### 1. Create DPR Entry

```bash
# For Civil, Erection, Roofing
curl -X POST http://localhost:3000/api/v1/site/{siteId}/dpr-peb \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "date": "2026-05-10",
    "section": "civil",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Foundation Excavation",
        "actualQty": 50,
        "uom": "m³",
        "remarks": "Excavation completed for foundation",
        "progressPhotos": []
      },
      {
        "itemCode": "C002",
        "itemName": "Concrete Casting",
        "actualQty": 30,
        "uom": "m³",
        "remarks": "Concrete casting completed",
        "progressPhotos": []
      }
    ]
  }'

# For Fabrication (with assembly mark)
curl -X POST http://localhost:3000/api/v1/site/{siteId}/dpr-peb \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "fabrication",
    "date": "2026-05-10",
    "section": "fabrication",
    "items": [
      {
        "itemCode": "F001",
        "itemName": "Column Fabrication",
        "assemblyMark": "COL-001",
        "actualQty": 10,
        "uom": "nos",
        "remarks": "Column fabrication completed",
        "progressPhotos": []
      },
      {
        "itemCode": "F002",
        "itemName": "Beam Fabrication",
        "assemblyMark": "BM-001",
        "actualQty": 15,
        "uom": "nos",
        "remarks": "Beam fabrication completed",
        "progressPhotos": []
      }
    ]
  }'
```

### 2. Get DPR Entries

```bash
# Get all DPR entries
curl -X GET http://localhost:3000/api/v1/site/{siteId}/dpr-peb \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get DPR entries by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/dpr-peb?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get DPR entries by date
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/dpr-peb?date=2026-05-10" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get DPR entries by section
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/dpr-peb?section=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get DPR Entry by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/dpr-peb/{dprId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Update DPR Entry

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/dpr-peb/{dprId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Foundation Excavation",
        "actualQty": 60,
        "remarks": "Updated excavation quantity"
      }
    ]
  }'
```

### 5. Delete DPR Entry

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/dpr-peb/{dprId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

---

## Dispatch

### 1. Create Dispatch

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-dispatch \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "dispatchNumber": "DISP-2026-001",
    "dispatchDate": "2026-05-15",
    "vehicleNumber": "GJ-01-AB-1234",
    "driverName": "Ramesh Patel",
    "driverPhone": "9876543212",
    "items": [
      {
        "itemCode": "C001",
        "itemName": "Concrete M20",
        "quantity": 50,
        "unit": "m³",
        "weight": 120000,
        "remarks": "Concrete for foundation"
      }
    ],
    "remarks": "Dispatch to site for foundation work",
    "deliveryStatus": "pending"
  }'
```

### 2. Get Dispatch Records

```bash
# Get all dispatch records
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-dispatch \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get dispatch by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-dispatch?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get dispatch by status
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-dispatch?deliveryStatus=pending" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get Dispatch by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-dispatch/{dispatchId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Update Dispatch

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/peb-dispatch/{dispatchId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "deliveryStatus": "in_transit",
    "items": [
      {
        "itemCode": "C001",
        "quantity": 55
      }
    ]
  }'
```

### 5. Delete Dispatch

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/peb-dispatch/{dispatchId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

---

## Handover

### 1. Create Handover

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-handover \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "workType": "civil",
    "handoverNumber": "HO-2026-001",
    "clientRepresentative": "Mr. Sharma",
    "clientContact": "9876543213",
    "checklist": [
      {
        "item": "Foundation completion",
        "status": true,
        "documents": [],
        "remarks": "Foundation completed as per design"
      },
      {
        "item": "Quality inspection",
        "status": true,
        "documents": [],
        "remarks": "Quality inspection passed"
      },
      {
        "item": "Documentation",
        "status": false,
        "documents": [],
        "remarks": "Pending final documentation"
      }
    ],
    "remarks": "Civil work handover pending documentation"
  }'
```

### 2. Get Handover Records

```bash
# Get all handover records
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-handover \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get handover by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-handover?workType=civil" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get handover by status
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/peb-handover?status=pending" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Get Handover by ID

```bash
curl -X GET http://localhost:3000/api/v1/site/{siteId}/peb-handover/{handoverId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 4. Update Handover

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/peb-handover/{handoverId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "checklist": [
      {
        "item": "Documentation",
        "status": true,
        "remarks": "Documentation completed"
      }
    ],
    "remarks": "All checklist items completed"
  }'
```

### 5. Approve Handover

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/peb-handover/approve \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "handoverId": "{handoverId}",
    "workType": "civil"
  }'
```

---

## Attendance

### Attendance Work Types

The attendance module now supports all 8 work types:

```typescript
const ATTENDANCE_WORK_TYPES = {
  CIVIL: 'civil_work',
  ERECTION: 'erection_work',
  ROOFING: 'roofing_work',
  FABRICATION: 'fabrication_work',
  MECHANICAL: 'mechanical_work',
  INSULATION: 'insulation_work',
  STRUCTURE: 'structure_work',
  PEB: 'peb_work'
}
```

### 1. Create Attendance

```bash
# For Civil Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "civil_work",
    "status": "present",
    "totalHours": 8,
    "ot": 2
  }'

# For Erection Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "erection_work",
    "status": "present",
    "totalHours": 9,
    "ot": 1
  }'

# For Roofing Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "roofing_work",
    "status": "present",
    "totalHours": 8,
    "ot": 0
  }'

# For Fabrication Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "fabrication_work",
    "status": "present",
    "totalHours": 10,
    "ot": 2
  }'

# For Mechanical Work (Existing)
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "mechanical_work",
    "status": "present",
    "totalHours": 8,
    "ot": 1
  }'

# For Insulation Work (Existing)
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "insulation_work",
    "status": "present",
    "totalHours": 8,
    "ot": 0
  }'

# For Structure Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "structure_work",
    "status": "present",
    "totalHours": 9,
    "ot": 1
  }'

# For PEB Work
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "manpowerId": "{manpowerId}",
    "date": "2026-05-10",
    "type": "peb_work",
    "status": "present",
    "totalHours": 8,
    "ot": 2
  }'
```

### 2. Get Attendance Records

```bash
# Get all attendance records
curl -X GET http://localhost:3000/api/v1/site/{siteId}/attendance \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get attendance by work type
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/attendance?type=civil_work" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get attendance by date
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/attendance?date=2026-05-10" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get attendance by manpower
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/attendance?manpowerId={manpowerId}" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"

# Get attendance by status
curl -X GET "http://localhost:3000/api/v1/site/{siteId}/attendance?status=present" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 3. Update Attendance

```bash
curl -X PUT http://localhost:3000/api/v1/site/{siteId}/attendance/{attendanceId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "status": "present",
    "totalHours": 9,
    "ot": 3
  }'
```

### 4. Delete Attendance

```bash
curl -X DELETE http://localhost:3000/api/v1/site/{siteId}/attendance/{attendanceId} \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>"
```

### 5. Bulk Mark Attendance

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance/multiple \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "date": "2026-05-10",
    "type": "civil_work",
    "attendance": [
      {
        "manpowerId": "{manpowerId1}",
        "status": "present",
        "totalHours": 8,
        "ot": 0
      },
      {
        "manpowerId": "{manpowerId2}",
        "status": "present",
        "totalHours": 8,
        "ot": 2
      },
      {
        "manpowerId": "{manpowerId3}",
        "status": "absent",
        "totalHours": 0,
        "ot": 0
      }
    ]
  }'
```

### 6. Generate Attendance Report

```bash
curl -X POST http://localhost:3000/api/v1/site/{siteId}/attendance/generate \
  -H "Content-Type: application/json" \
  -H "Cookie: session=<your-session-cookie>" \
  -d '{
    "startDate": "2026-05-01",
    "endDate": "2026-05-10",
    "type": "civil_work"
  }'
```

---

## Quick Reference

### Work Type Query Parameter

All GET requests support the `workType` query parameter to filter by work type:

```bash
?workType=civil
?workType=erection
?workType=roofing
?workType=fabrication
?workType=mechanical
?workType=insulation
?workType=structure
?workType=peb
```

### Attendance Type Parameter

Attendance requests use the `type` parameter:

```bash
?type=civil_work
?type=erection_work
?type=roofing_work
?type=fabrication_work
?type=mechanical_work
?type=insulation_work
?type=structure_work
?type=peb_work
```

### Common Query Parameters

```bash
# Pagination
?page=1&limit=20

# Sorting
?sort=createdAt&order=desc

# Filtering
?status=pending
?date=2026-05-10
?search=keyword
```

---

## Error Handling

### Common Error Responses

```json
{
  "error": "Error message here"
}
```

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

---

## Testing Checklist

### Work Type Configuration
- [ ] Create work type configuration
- [ ] Get work type configuration
- [ ] Update work type configuration

### Site Creation
- [ ] Create site with work types
- [ ] Get site details
- [ ] Update site work types

### Rate Upload
- [ ] Upload rate for each work type
- [ ] Get rates by work type
- [ ] Update rate upload
- [ ] Delete rate upload

### Procurement
- [ ] Create material request
- [ ] Get requests by work type
- [ ] Approve request
- [ ] Create vendor
- [ ] Get vendors by work type
- [ ] Create purchase order
- [ ] Get POs by work type
- [ ] Approve PO
- [ ] Get approvals

### Inventory
- [ ] Create inventory item
- [ ] Get inventory by work type
- [ ] Add movement
- [ ] Reserve stock
- [ ] Consume stock

### BOQ Upload
- [ ] Upload BOQ (fabrication only)
- [ ] Get assembly marks
- [ ] Get BOQ items

### DPR Setup
- [ ] Create DPR setup for each work type
- [ ] Get setup by work type
- [ ] Update setup
- [ ] Delete setup

### DPR Entry
- [ ] Create DPR entry for each work type
- [ ] Create entry with assembly mark (fabrication)
- [ ] Get entries by work type
- [ ] Update entry
- [ ] Delete entry

### Dispatch
- [ ] Create dispatch for each work type
- [ ] Get dispatch by work type
- [ ] Update dispatch
- [ ] Delete dispatch

### Handover
- [ ] Create handover for each work type
- [ ] Get handover by work type
- [ ] Update handover
- [ ] Approve handover

### Attendance
- [ ] Create attendance for all 8 work types
- [ ] Get attendance by type
- [ ] Update attendance
- [ ] Bulk mark attendance
- [ ] Generate attendance report

---

## Notes for Frontend Developers

1. **Authentication**: All requests require authentication. Use the session cookie or token.
2. **Work Type Parameter**: Most GET requests support the `workType` query parameter for filtering.
3. **BOQ Upload**: BOQ upload is only allowed for fabrication work type.
4. **Assembly Marks**: Assembly marks are only relevant for fabrication work type in DPR entry.
5. **Attendance Types**: Attendance now supports all 8 work types with the `_work` suffix.
6. **Sequential Flow**: Ensure that previous steps are completed before moving to the next step.
7. **Error Handling**: Always handle errors gracefully and display appropriate messages to users.
8. **Validation**: Validate all inputs before making API calls.
9. **Loading States**: Show loading indicators during API calls.
10. **Refresh Data**: Refresh data after successful create/update/delete operations.

---

**End of Document**
