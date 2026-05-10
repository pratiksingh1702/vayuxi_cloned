# PEB Work Type Implementation - Current Scope

**Document Version:** 1.0  
**Date:** May 9, 2026  
**Prepared For:** CEO Review & Implementation  
**System:** BE-VAYUXI

---

## Table of Contents

1. [Objective](#objective)
2. [Current Work Types](#current-work-types)
3. [New Work Types to Add](#new-work-types-to-add)
4. [Modules to Implement](#modules-to-implement)
5. [Implementation Plan](#implementation-plan)
6. [Backend Changes](#backend-changes)
7. [Frontend Changes](#frontend-changes)
8. [Database Changes](#database-changes)
9. [API Changes](#api-changes)
10. [Timeline & Effort](#timeline--effort)

---

## Objective

Implement the following modules for 4 new work types (CIVIL, ERECTION, ROOFING, FABRICATION) while maintaining existing work types (MECHANICAL, INSULATION, STRUCTURE, PEB):

1. **Site Creation** - Add work type selection
2. **Rate Upload** - Work type-specific rate upload
3. **Procurement** - New module including material purchase functionality
4. **Inventory** - Work type-specific inventory
5. **BOQ Upload** - For fabrication work type only
6. **DPR Setup** - Work type-specific DPR setup
7. **DPR Entry** - Work type-specific DPR entry
8. **Dispatch** - Work type-specific dispatch
9. **Handover** - Work type-specific handover

---

## Current Work Types

Existing work types in the system:
- **MECHANICAL** - Mechanical work
- **INSULATION** - Insulation work
- **STRUCTURE** - Structure work
- **PEB** - PEB work

---

## New Work Types to Add

New work types to be added:
- **CIVIL** - Civil construction work
- **ERECTION** - Erection work
- **ROOFING** - Roofing work
- **FABRICATION** - Fabrication work

---

## Modules to Implement

### Module 1: Site Creation

**Current State:**
- Site creation exists at `/peb-work/create-site`
- No work type selection
- Generic site configuration

**Required Changes:**
- Add work type selection during site creation
- Support for 8 work types (4 existing + 4 new)
- Work type configuration per site

---

### Module 2: Rate Upload

**Current State:**
- Rate upload API exists
- No work type separation
- Generic rate upload

**Required Changes:**
- Add work type field to rate upload
- Work type-specific rate upload
- Filter rates by work type
- Use existing rate upload API with work type parameter

---

### Module 3: Procurement (NEW MODULE)

**Current State:**
- Material purchase exists at `/peb-work/material-purchase`
- No procurement module
- Material purchase is standalone

**Required Changes:**
- Create new procurement module
- Move material purchase functionality to procurement
- Add features:
  - Material requests
  - Vendor management
  - Purchase orders
  - Approval workflow
- Work type-specific procurement

---

### Module 4: Inventory

**Current State:**
- Inventory exists at `/peb-work/inventory`
- No work type separation
- Generic inventory tracking

**Required Changes:**
- Add work type field to inventory
- Work type-specific inventory tracking
- Filter inventory by work type
- Separate stock tracking per work type

---

### Module 5: BOQ Upload

**Current State:**
- BOQ upload API exists at `/api/v1/site/[site]/boq-structure/upload`
- No work type integration
- Not used in DPR entry

**Required Changes:**
- Add work type field to BOQ upload (default: fabrication)
- Extract assembly marks from BOQ
- Use assembly marks in DPR entry (fabrication only)
- BOQ validation for fabrication work type

---

### Module 6: DPR Setup

**Current State:**
- DPR setup exists and works perfectly
- No work type separation
- Generic DPR setup

**Required Changes:**
- Add work type field to DPR setup
- Work type-specific DPR setup
- Filter DPR setup by work type
- Separate configuration per work type

---

### Module 7: DPR Entry

**Current State:**
- DPR entry exists with simplified fields
- No work type separation
- Generic DPR entry

**Required Changes:**
- Add work type field to DPR entry
- Work type-specific DPR entry
- Add assembly mark field for fabrication work type
- Filter DPR entry by work type

---

### Module 8: Dispatch

**Current State:**
- Dispatch exists at `/peb-work/dispatch`
- Basic functionality
- No work type separation

**Required Changes:**
- Add work type field to dispatch
- Work type-specific dispatch
- Dispatch validation by work type
- Enhanced dispatch features

---

### Module 9: Handover

**Current State:**
- Handover exists at `/peb-work/handover`
- Basic functionality
- No work type separation

**Required Changes:**
- Add work type field to handover
- Work type-specific handover
- Pending work tracking per work type
- Enhanced handover features

---

## Implementation Plan

### Phase 1: Work Type Configuration (3-4 days)

#### Backend Changes

**New Model:**
```typescript
// src/models/siteWorkTypeConfig.model.ts
interface SiteWorkTypeConfig {
  siteId: string;
  workTypes: {
    civil: { enabled: boolean; sequence: number; };
    erection: { enabled: boolean; sequence: number; };
    roofing: { enabled: boolean; sequence: number; };
    fabrication: { enabled: boolean; sequence: number; boqEnabled: boolean; };
    mechanical: { enabled: boolean; sequence: number; };
    insulation: { enabled: boolean; sequence: number; };
    structure: { enabled: boolean; sequence: number; };
    peb: { enabled: boolean; sequence: number; };
  };
  company: string;
  siteId: string;
  createdBy: string;
  updatedBy: string;
}
```

**New Service:**
```typescript
// src/services/siteWorkTypeConfig.service.ts
class SiteWorkTypeConfigService {
  public async createConfig(siteId: string, companyId: string, config: any, user: any)
  public async getConfig(siteId: string, companyId: string)
  public async updateConfig(siteId: string, companyId: string, config: any, user: any)
}
```

**New APIs:**
```
POST   /api/v1/site/[site]/work-type-config
GET    /api/v1/site/[site]/work-type-config
PUT    /api/v1/site/[site]/work-type-config
```

**Modify Existing Model:**
```typescript
// src/models/site.models.ts
// Add workTypeConfig field to Site schema
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/create-site.tsx
// Add work type selection checkboxes
// Add work type sequence configuration
// Add BOQ enable option for fabrication
```

**New Page:**
```typescript
// src/pages/peb-work/work-type-config.tsx
// Work type configuration UI
// Enable/disable work types
// Set sequence
// Configure dependencies
```

---

### Phase 2: Site Creation Enhancement (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/pebProject.model.ts
// Add workTypes field (array of enabled work types)
```

**Modify Service:**
```typescript
// src/services/pebProject.service.ts
// Add work type validation
// Add work type config creation
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/create-site.tsx
// Add work type multi-select
// Show work type configuration options
// Validate work type selection
```

---

### Phase 3: Procurement Module Creation (1-2 weeks)

#### Backend Changes

**New Models:**

1. **Procurement Request**
```typescript
// src/models/procurementRequest.model.ts
interface ProcurementRequest {
  requestNumber: string;
  workType: string; // civil, erection, roofing, fabrication, mechanical, insulation, structure, peb
  items: ProcurementRequestItem[];
  requestedBy: string;
  status: string;
  priority: string;
  expectedDeliveryDate: Date;
  remarks: string;
  company: string;
  siteId: string;
  createdBy: string;
  updatedBy: string;
}
```

2. **Procurement Vendor**
```typescript
// src/models/procurementVendor.model.ts
interface ProcurementVendor {
  vendorName: string;
  vendorCode: string;
  contactPerson: string;
  phoneNumber: string;
  email: string;
  address: string;
  materials: string[]; // Material types supplied
  workTypes: string[]; // Work types supported
  rating: number;
  status: string;
  company: string;
  siteId: string;
  createdBy: string;
  updatedBy: string;
}
```

3. **Procurement Purchase Order**
```typescript
// src/models/procurementPurchaseOrder.model.ts
interface ProcurementPurchaseOrder {
  poNumber: string;
  workType: string;
  vendorId: string;
  requestId: string;
  items: PurchaseOrderItem[];
  totalAmount: number;
  status: string;
  orderDate: Date;
  expectedDeliveryDate: Date;
  remarks: string;
  company: string;
  siteId: string;
  createdBy: string;
  updatedBy: string;
}
```

4. **Procurement Approval**
```typescript
// src/models/procurementApproval.model.ts
interface ProcurementApproval {
  entityType: string; // request, purchase_order
  entityId: string;
  workType: string;
  approverId: string;
  status: string;
  comments: string;
  approvedAt: Date;
  company: string;
  siteId: string;
  createdBy: string;
}
```

**New Services:**

1. **Procurement Request Service**
```typescript
// src/services/procurementRequest.service.ts
class ProcurementRequestService {
  public async createRequest(siteId: string, companyId: string, data: any, user: any)
  public async getRequests(siteId: string, companyId: string, workType?: string)
  public async getRequestById(siteId: string, companyId: string, id: string)
  public async updateRequest(siteId: string, companyId: string, id: string, data: any, user: any)
  public async deleteRequest(siteId: string, companyId: string, id: string)
  public async approveRequest(siteId: string, companyId: string, id: string, user: any)
}
```

2. **Procurement Vendor Service**
```typescript
// src/services/procurementVendor.service.ts
class ProcurementVendorService {
  public async createVendor(siteId: string, companyId: string, data: any, user: any)
  public async getVendors(siteId: string, companyId: string, workType?: string)
  public async getVendorById(siteId: string, companyId: string, id: string)
  public async updateVendor(siteId: string, companyId: string, id: string, data: any, user: any)
  public async deleteVendor(siteId: string, companyId: string, id: string)
}
```

3. **Procurement Purchase Order Service**
```typescript
// src/services/procurementPurchaseOrder.service.ts
class ProcurementPurchaseOrderService {
  public async createPurchaseOrder(siteId: string, companyId: string, data: any, user: any)
  public async getPurchaseOrders(siteId: string, companyId: string, workType?: string)
  public async getPurchaseOrderById(siteId: string, companyId: string, id: string)
  public async updatePurchaseOrder(siteId: string, companyId: string, id: string, data: any, user: any)
  public async deletePurchaseOrder(siteId: string, companyId: string, id: string)
  public async approvePurchaseOrder(siteId: string, companyId: string, id: string, user: any)
}
```

4. **Procurement Approval Service**
```typescript
// src/services/procurementApproval.service.ts
class ProcurementApprovalService {
  public async createApproval(siteId: string, companyId: string, data: any, user: any)
  public async getApprovals(siteId: string, companyId: string, workType?: string)
  public async getApprovalById(siteId: string, companyId: string, id: string)
  public async updateApproval(siteId: string, companyId: string, id: string, data: any, user: any)
}
```

**New APIs:**

```
// Procurement Requests
POST   /api/v1/site/[site]/procurement/requests
GET    /api/v1/site/[site]/procurement/requests
GET    /api/v1/site/[site]/procurement/requests/[id]
PUT    /api/v1/site/[site]/procurement/requests/[id]
DELETE /api/v1/site/[site]/procurement/requests/[id]
POST   /api/v1/site/[site]/procurement/requests/[id]/approve

// Procurement Vendors
POST   /api/v1/site/[site]/procurement/vendors
GET    /api/v1/site/[site]/procurement/vendors
GET    /api/v1/site/[site]/procurement/vendors/[id]
PUT    /api/v1/site/[site]/procurement/vendors/[id]
DELETE /api/v1/site/[site]/procurement/vendors/[id]

// Procurement Purchase Orders
POST   /api/v1/site/[site]/procurement/purchase-orders
GET    /api/v1/site/[site]/procurement/purchase-orders
GET    /api/v1/site/[site]/procurement/purchase-orders/[id]
PUT    /api/v1/site/[site]/procurement/purchase-orders/[id]
DELETE /api/v1/site/[site]/procurement/purchase-orders/[id]
POST   /api/v1/site/[site]/procurement/purchase-orders/[id]/approve

// Procurement Approvals
POST   /api/v1/site/[site]/procurement/approvals
GET    /api/v1/site/[site]/procurement/approvals
GET    /api/v1/site/[site]/procurement/approvals/[id]
PUT    /api/v1/site/[site]/procurement/approvals/[id]
```

**Modify Existing:**
- Move material purchase functionality to procurement
- Add work type field to material purchase model
- Update material purchase service to use work type

#### Frontend Changes

**New Pages:**

1. **Procurement Dashboard**
```typescript
// src/pages/peb-work/procurement/index.tsx
// Main procurement dashboard
// Work type selector
// Summary cards (requests, vendors, POs, approvals)
```

2. **Material Requests**
```typescript
// src/pages/peb-work/procurement/requests/index.tsx
// List of material requests
// Work type filter
// Status filter

// src/pages/peb-work/procurement/requests/add.tsx
// Add material request form
// Work type selection
// Item details
// Priority selection
```

3. **Vendors**
```typescript
// src/pages/peb-work/procurement/vendors/index.tsx
// List of vendors
// Work type filter
// Rating display

// src/pages/peb-work/procurement/vendors/add.tsx
// Add vendor form
// Work type selection
// Material types supplied
// Contact details
```

4. **Purchase Orders**
```typescript
// src/pages/peb-work/procurement/purchase-orders/index.tsx
// List of purchase orders
// Work type filter
// Status filter
// Vendor info

// src/pages/peb-work/procurement/purchase-orders/add.tsx
// Add purchase order form
// Work type selection
// Vendor selection
// Request selection
// Item details
```

5. **Approvals**
```typescript
// src/pages/peb-work/procurement/approvals/index.tsx
// Approval dashboard
// Pending approvals
// Work type filter
// Approval actions
```

**Modify Page:**
- Remove `/peb-work/material-purchase.tsx` (functionality moved to procurement)

**Navigation:**
- Add Procurement section to sidebar
- Sub-navigation: Requests, Vendors, Purchase Orders, Approvals

---

### Phase 4: Rate Upload Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/RateUpload.model.ts
// Add workType field
```

**Modify Service:**
```typescript
// src/services/rateAnalysis.service.ts
// Add work type filtering
// Add work type validation
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/rate-upload/*
// Add workType query parameter
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/setup/rates/upload.tsx
// Add work type selector
// Filter by work type
```

---

### Phase 5: Inventory Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/pebInventory.model.ts
// Add workType field
```

**Modify Service:**
```typescript
// src/services/pebInventory.service.ts
// Add work type filtering
// Add work type validation
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/peb-inventory/*
// Add workType query parameter
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/inventory.tsx
// Add work type selector
// Filter by work type
// Show work type-specific stock
```

---

### Phase 6: BOQ Upload Work Type Integration (3-4 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/boq.model.ts
// Add workType field (default: fabrication)
```

**Modify Model:**
```typescript
// src/models/boqStructure.model.ts
// Add assembly mark extraction logic
// Add work type validation
```

**New Service:**
```typescript
// src/services/boqAssembly.service.ts
class BoqAssemblyService {
  public async extractAssemblyMarks(boqId: string)
  public async getAssemblyMarks(boqId: string)
  public async validateAssemblyMark(boqId: string, assemblyMark: string)
}
```

**Modify Service:**
```typescript
// src/services/boqStructure.service.ts
// Add work type support
// Add assembly mark extraction
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/boq-structure/upload.ts
// Add workType parameter (default: fabrication)
// Only allow fabrication work type for BOQ upload

// New endpoint
GET    /api/v1/site/[site]/boq/[boqId]/assembly-marks
```

#### Frontend Changes

**New Page:**
```typescript
// src/pages/peb-work/boq-upload.tsx
// BOQ upload form
// Work type selector (only fabrication enabled)
// Assembly mark preview
// Validation status
```

**Modify Pages:**
```typescript
// src/pages/peb-work/dpr-entry.tsx
// Add assembly mark field for fabrication work type
// Auto-populate from BOQ
// Validate against BOQ assembly marks

// src/pages/peb-work/unified-dashboard.tsx
// Add BOQ status for fabrication
// Show assembly mark count
```

---

### Phase 7: DPR Setup Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/pebDprSetup.model.ts
// Add workType field
```

**Modify Service:**
```typescript
// src/services/pebDprSetup.service.ts
// Add work type filtering
// Add work type validation
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/peb-dpr-setup/*
// Add workType query parameter
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/unified-dashboard.tsx
// Add work type tabs to DPR Setup
// Filter by work type
// Show work type-specific configuration
```

---

### Phase 8: DPR Entry Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/dprPeb.model.ts
// Add workType field
// Add assemblyMark field (for fabrication)
```

**Modify Service:**
```typescript
// src/services/dprPeb.service.ts
// Add work type filtering
// Add assembly mark validation (for fabrication)
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/dpr-peb/*
// Add workType query parameter
// Add assemblyMark field for fabrication
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/dpr-entry.tsx
// Add work type selector
// Add assembly mark field for fabrication
// Auto-populate assembly marks from BOQ
// Filter by work type
```

---

### Phase 9: Dispatch Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/pebDispatch.model.ts
// Add workType field
```

**Modify Service:**
```typescript
// src/services/pebDispatch.service.ts
// Add work type filtering
// Add work type validation
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/peb-dispatch/*
// Add workType query parameter
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/dispatch.tsx
// Add work type selector
// Filter by work type
// Show work type-specific dispatch
```

---

### Phase 10: Handover Work Type Separation (2-3 days)

#### Backend Changes

**Modify Model:**
```typescript
// src/models/pebHandover.model.ts
// Add workType field
```

**Modify Service:**
```typescript
// src/services/pebHandover.service.ts
// Add work type filtering
// Add work type validation
```

**Modify API:**
```typescript
// src/pages/api/v1/site/[site]/peb-handover/*
// Add workType query parameter
// Filter by work type
```

#### Frontend Changes

**Modify Page:**
```typescript
// src/pages/peb-work/handover.tsx
// Add work type selector
// Filter by work type
// Show work type-specific handover
```

---

## Backend Changes Summary

### New Models (5)

1. `siteWorkTypeConfig.model.ts` - Work type configuration
2. `procurementRequest.model.ts` - Material requests
3. `procurementVendor.model.ts` - Vendor management
4. `procurementPurchaseOrder.model.ts` - Purchase orders
5. `procurementApproval.model.ts` - Approval workflow

### Modified Models (9)

1. `site.models.ts` - Add workTypeConfig field
2. `pebProject.model.ts` - Add workTypes field
3. `RateUpload.model.ts` - Add workType field
4. `pebInventory.model.ts` - Add workType field
5. `pebMaterialPurchase.model.ts` - Add workType field
6. `boq.model.ts` - Add workType field
7. `boqStructure.model.ts` - Add assembly mark extraction
8. `dprPeb.model.ts` - Add workType, assemblyMark fields
9. `pebDprSetup.model.ts` - Add workType field
10. `pebDispatch.model.ts` - Add workType field
11. `pebHandover.model.ts` - Add workType field

### New Services (5)

1. `siteWorkTypeConfig.service.ts` - Work type configuration
2. `procurementRequest.service.ts` - Material requests
3. `procurementVendor.service.ts` - Vendor management
4. `procurementPurchaseOrder.service.ts` - Purchase orders
5. `procurementApproval.service.ts` - Approval workflow
6. `boqAssembly.service.ts` - Assembly mark extraction

### Modified Services (9)

1. `pebProject.service.ts` - Add work type support
2. `rateAnalysis.service.ts` - Add work type filtering
3. `pebInventory.service.ts` - Add work type filtering
4. `pebMaterialPurchase.service.ts` - Add work type support
5. `boqStructure.service.ts` - Add work type support
6. `pebDprSetup.service.ts` - Add work type filtering
7. `dprPeb.service.ts` - Add work type filtering, assembly mark validation
8. `pebDispatch.service.ts` - Add work type filtering
9. `pebHandover.service.ts` - Add work type filtering

---

## Frontend Changes Summary

### New Pages (10)

1. `/peb-work/work-type-config.tsx` - Work type configuration
2. `/peb-work/procurement/index.tsx` - Procurement dashboard
3. `/peb-work/procurement/requests/index.tsx` - Material requests list
4. `/peb-work/procurement/requests/add.tsx` - Add material request
5. `/peb-work/procurement/vendors/index.tsx` - Vendor list
6. `/peb-work/procurement/vendors/add.tsx` - Add vendor
7. `/peb-work/procurement/purchase-orders/index.tsx` - Purchase orders list
8. `/peb-work/procurement/purchase-orders/add.tsx` - Add purchase order
9. `/peb-work/procurement/approvals/index.tsx` - Approvals dashboard
10. `/peb-work/boq-upload.tsx` - BOQ upload

### Modified Pages (8)

1. `/peb-work/create-site.tsx` - Add work type selection
2. `/peb-work/inventory.tsx` - Add work type selector
3. `/peb-work/dpr-entry.tsx` - Add work type selector, assembly mark
4. `/peb-work/unified-dashboard.tsx` - Add work type tabs, BOQ status
5. `/peb-work/dispatch.tsx` - Add work type selector
6. `/peb-work/handover.tsx` - Add work type selector
7. `/setup/rates/upload.tsx` - Add work type selector
8. `/peb-work/material-purchase.tsx` - Remove (moved to procurement)

### Navigation Structure

```
Sidebar Navigation:
├── PEB Work
│   ├── Dashboard
│   ├── Site Creation
│   ├── Work Type Config (NEW)
│   ├── Procurement (NEW)
│   │   ├── Requests
│   │   ├── Vendors
│   │   ├── Purchase Orders
│   │   └── Approvals
│   ├── Rate Upload
│   ├── Inventory
│   ├── BOQ Upload (NEW)
│   ├── DPR Entry
│   ├── Dispatch
│   └── Handover
└── Setup
    ├── Sites
    └── Rates
```

---

## Database Changes Summary

### New Collections (5)

1. `siteworktypeconfigs` - Work type configuration
2. `procurementrequests` - Material requests
3. `procurementvendors` - Vendor management
4. `procurementpurchaseorders` - Purchase orders
5. `procurementapprovals` - Approval workflow

### Modified Collections (11)

1. `sites` - Add workTypeConfig field
2. `pebprojects` - Add workTypes field
3. `rateuploads` - Add workType field
4. `pebinventories` - Add workType field
5. `pebmaterialpurchases` - Add workType field
6. `boqs` - Add workType field
7. `boqstructures` - Add assembly mark extraction
8. `dprpebs` - Add workType, assemblyMark fields
9. `pebdprsetups` - Add workType field
10. `pebdispatches` - Add workType field
11. `pebhandovers` - Add workType field

---

## API Changes Summary

### New API Endpoints (13)

```
// Work Type Config
POST   /api/v1/site/[site]/work-type-config
GET    /api/v1/site/[site]/work-type-config
PUT    /api/v1/site/[site]/work-type-config

// Procurement Requests
POST   /api/v1/site/[site]/procurement/requests
GET    /api/v1/site/[site]/procurement/requests
GET    /api/v1/site/[site]/procurement/requests/[id]
PUT    /api/v1/site/[site]/procurement/requests/[id]
DELETE /api/v1/site/[site]/procurement/requests/[id]
POST   /api/v1/site/[site]/procurement/requests/[id]/approve

// Procurement Vendors
POST   /api/v1/site/[site]/procurement/vendors
GET    /api/v1/site/[site]/procurement/vendors
GET    /api/v1/site/[site]/procurement/vendors/[id]
PUT    /api/v1/site/[site]/procurement/vendors/[id]
DELETE /api/v1/site/[site]/procurement/vendors/[id]

// Procurement Purchase Orders
POST   /api/v1/site/[site]/procurement/purchase-orders
GET    /api/v1/site/[site]/procurement/purchase-orders
GET    /api/v1/site/[site]/procurement/purchase-orders/[id]
PUT    /api/v1/site/[site]/procurement/purchase-orders/[id]
DELETE /api/v1/site/[site]/procurement/purchase-orders/[id]
POST   /api/v1/site/[site]/procurement/purchase-orders/[id]/approve

// Procurement Approvals
POST   /api/v1/site/[site]/procurement/approvals
GET    /api/v1/site/[site]/procurement/approvals
GET    /api/v1/site/[site]/procurement/approvals/[id]
PUT    /api/v1/site/[site]/procurement/approvals/[id]

// BOQ Assembly Marks
GET    /api/v1/site/[site]/boq/[boqId]/assembly-marks
```

### Modified API Endpoints

All existing APIs will be modified to accept a `workType` query parameter:

```
GET    /api/v1/site/[site]/rate-upload?workType=civil
GET    /api/v1/site/[site]/peb-inventory?workType=civil
GET    /api/v1/site/[site]/peb-material-purchase?workType=civil
GET    /api/v1/site/[site]/boq-structure/upload?workType=fabrication
GET    /api/v1/site/[site]/peb-dpr-setup?workType=civil
GET    /api/v1/site/[site]/dpr-peb?workType=civil
GET    /api/v1/site/[site]/peb-dispatch?workType=civil
GET    /api/v1/site/[site]/peb-handover?workType=civil
```

---

## Timeline & Effort

### Phase-wise Timeline

| Phase | Duration | Effort (Person-Days) | Description |
|-------|----------|----------------------|-------------|
| Phase 1: Work Type Config | 3-4 days | 3-4 | Configuration system |
| Phase 2: Site Creation | 2-3 days | 2-3 | Work type selection |
| Phase 3: Procurement | 1-2 weeks | 10-14 | Full procurement module |
| Phase 4: Rate Upload | 2-3 days | 2-3 | Work type separation |
| Phase 5: Inventory | 2-3 days | 2-3 | Work type separation |
| Phase 6: BOQ Upload | 3-4 days | 3-4 | Assembly mark integration |
| Phase 7: DPR Setup | 2-3 days | 2-3 | Work type separation |
| Phase 8: DPR Entry | 2-3 days | 2-3 | Work type separation |
| Phase 9: Dispatch | 2-3 days | 2-3 | Work type separation |
| Phase 10: Handover | 2-3 days | 2-3 | Work type separation |
| **Total** | **4-5 weeks** | **30-41** | - |

### Resource Requirements

- **Backend Developers**: 2
- **Frontend Developers**: 2
- **QA Engineers**: 1

### Critical Path

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8 → Phase 9 → Phase 10
```

---

## Work Type Constants

```typescript
// src/constants/workTypes.ts
export const WORK_TYPES = {
  CIVIL: 'civil',
  ERECTION: 'erection',
  ROOFING: 'roofing',
  FABRICATION: 'fabrication',
  MECHANICAL: 'mechanical',
  INSULATION: 'insulation',
  STRUCTURE: 'structure',
  PEB: 'peb'
} as const;

export const WORK_TYPE_LABELS = {
  civil: 'Civil',
  erection: 'Erection',
  roofing: 'Roofing',
  fabrication: 'Fabrication',
  mechanical: 'Mechanical',
  insulation: 'Insulation',
  structure: 'Structure',
  peb: 'PEB'
} as const;

export const BOQ_ENABLED_WORK_TYPES = ['fabrication'] as const;
```

---

## Data Flow Diagram

```
Site Creation (with Work Types)
         ↓
Work Type Configuration
         ↓
Rate Upload (per Work Type)
         ↓
Procurement (per Work Type)
         ↓
Inventory (per Work Type)
         ↓
BOQ Upload (Fabrication Only)
         ↓
DPR Setup (per Work Type)
         ↓
DPR Entry (per Work Type)
         ↓
Dispatch (per Work Type)
         ↓
Handover (per Work Type)
```

---

## Validation Rules

### Work Type Validation
- Site must have at least one work type enabled
- Work types must have unique sequence numbers
- BOQ upload only allowed for fabrication work type

### Procurement Validation
- Material request must have work type
- Vendor must support selected work type
- Purchase order must have work type
- Approval must match work type

### BOQ Validation
- Only fabrication work type can upload BOQ
- Assembly marks must be unique
- Assembly marks must be used in DPR entry (fabrication)

### DPR Validation
- DPR entry must have work type
- Assembly mark validation for fabrication
- Work type must match DPR setup

---

## Migration Strategy

### Step 1: Add Work Type Field (1 day)
- Add workType field to all relevant collections
- Default existing records to 'peb' (most common)
- Update indexes

### Step 2: Create Work Type Config (1 day)
- Create default work type config for existing sites
- Enable all 8 work types by default
- Set default sequence

### Step 3: Deploy New Features (2-3 days)
- Deploy new models and services
- Deploy new APIs
- Deploy new pages
- Update existing pages

### Step 4: Testing (2-3 days)
- Unit tests
- Integration tests
- End-to-end tests
- User acceptance testing

---

## Conclusion

This implementation plan focuses on adding 4 new work types (CIVIL, ERECTION, ROOFING, FABRICATION) to the existing system while maintaining the 4 current work types (MECHANICAL, INSULATION, STRUCTURE, PEB). The plan covers all 9 required modules with work type separation and the new procurement module.

The estimated timeline is 4-5 weeks with 30-41 person-days of effort. The implementation is phased to minimize disruption and ensure smooth integration.

**Next Steps:**
1. CEO review and approval
2. Resource allocation
3. Start Phase 1: Work Type Configuration

---

**End of Document**
