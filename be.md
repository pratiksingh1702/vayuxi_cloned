# Complete API Workflow - Dynamic Insulation DPR System

## Overview
This document provides a complete end-to-end API workflow for testing the dynamic insulation DPR system, from site creation to sheet generation.

**Testing Date**: February 24, 2026  
**System**: Dynamic Insulation Material System  
**Base URL**: `http://localhost:3000`

---

## Prerequisites

1. **Authentication Token**: You need a valid JWT token
2. **Company ID**: Your company ID from the database
3. **User ID**: Your user ID for audit trails

---

## Complete Workflow (Step-by-Step)

### Step 1: Create Site

**Endpoint**: `POST /api/v1/site`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "siteName": "Dynamic Insulation Test Site",
  "address": "Test Address, City",
  "company": "YOUR_COMPANY_ID"
}'
```

**Response**:
```json
{
  "success": true,
  "site": {
    "_id": "SITE_ID_HERE",
    "siteName": "Dynamic Insulation Test Site",
    "company": "YOUR_COMPANY_ID"
  }
}
```

**Save**: `SITE_ID` for next steps

---

### Step 2: Upload Insulation Rates (CSV)

**Endpoint**: `POST /api/v1/site/:siteId/rate/upload-csv`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/rate/upload-csv' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--form 'file=@"/path/to/insulation_rates.csv"' \
--form 'workType="insulation_work"'
```

**Sample CSV Content** (`insulation_rates.csv`):
```csv
Service Name,Unit,Rate
INSULATION WORK FOR PIPE WITH LRB 50MM THICKNESS,MTR,450
INSULATION WORK FOR SHELL WITH LRB 50MM THICKNESS,M2,850
INSULATION WORK FOR DOME WITH LRB 50MM THICKNESS,M2,900
CLADDING WORK WITH ALUMINIUM 24 SWG,M2,250
```

**Response**:
```json
{
  "success": true,
  "message": "Rates uploaded successfully",
  "ratesCount": 4
}
```

**Note**: This automatically initializes default insulation materials with dynamic field configurations!

---

### Step 3: Get Setup Materials (Verify Dynamic Configuration)

**Endpoint**: `GET /api/v1/insulation-dpr-setup/materials?siteId=SITE_ID`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/insulation-dpr-setup/materials?siteId=SITE_ID' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN'
```

**Response**:
```json
{
    "success": true,
    "data": [
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "length",
                        "label": "Length",
                        "role": "LENGTH",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "diameter",
                        "label": "Diameter",
                        "role": "DIAMETER",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": false,
                        "dropdown": "lengthUom",
                        "isUserAdded": false,
                        "visibleWhen": {
                            "geometryMode": "DIAMETER"
                        }
                    },
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": false,
                        "dropdown": "lengthUom",
                        "isUserAdded": false,
                        "visibleWhen": {
                            "geometryMode": "CIRCUMFERENCE"
                        }
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "geometryMode": "DIAMETER",
                    "lengthUom": "MM",
                    "areaUom": "M2",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": true,
                    "_id": "69c6d7c517dee0c3348999ff"
                }
            },
            "_id": "69c6d7c517dee0c3348999fe",
            "name": "SHELL",
            "materialCode": "SHELL",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/d6ec6543cb929ae51cad3699674b8028574c6a70.png",
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/c4fd9039b9be2c67276be3f38f4a1ee2ac0eb58a.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "SHELL",
                "_id": "69c6d7c517dee0c334899a00"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 0,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "z_height",
                        "label": "Z Height",
                        "role": "Z_HEIGHT",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "geometryMode": "CIRCUMFERENCE",
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": true,
                    "_id": "69c6d7c517dee0c334899a03"
                }
            },
            "_id": "69c6d7c517dee0c334899a02",
            "name": "DOME",
            "materialCode": "DOME",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/62a14365f7eddc3b532feb739f0b6c129396d7cc.png",
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/75e76798558aa48f45af7e6b9f885d19bea03068.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "DOME",
                "constantRules": "if z_height < (circumference/3.14)/3 then 1.27 else 1.75",
                "_id": "69c6d7c517dee0c334899a04"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 1,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "geometryMode": "CIRCUMFERENCE",
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": true,
                    "_id": "69c6d7c517dee0c334899a07"
                }
            },
            "_id": "69c6d7c517dee0c334899a06",
            "name": "FLAT END",
            "materialCode": "FLAT_END",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/Frame 45.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "FLAT_END",
                "_id": "69c6d7c517dee0c334899a08"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 2,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "slant_height",
                        "label": "G Slant Height",
                        "role": "slant_height",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a0b"
                }
            },
            "_id": "69c6d7c517dee0c334899a0a",
            "name": "CONE END",
            "materialCode": "CONE_END",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/Frame 46.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "CONE_END",
                "constantRules": "if slant_height > 3000 then 1 else 1.5",
                "_id": "69c6d7c517dee0c334899a0c"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 3,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "length",
                        "label": "Length",
                        "role": "LENGTH",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "circumference_1",
                        "label": "Circumference 1",
                        "role": "CIRCUMFERENCE_1",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a0f"
                }
            },
            "_id": "69c6d7c517dee0c334899a0e",
            "name": "REDUCER",
            "materialCode": "REDUCER",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/3d0a42c8c91a6691a6d5edd64537778a526642c5.png",
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/b9a76083c85361b395c45cc6ce581b5083b93ac2.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "REDUCER",
                "constantRules": "if length > 3000 then 1 else 1.5",
                "_id": "69c6d7c517dee0c334899a10"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 4,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a13"
                }
            },
            "_id": "69c6d7c517dee0c334899a12",
            "name": "FLANGE BOX-1",
            "materialCode": "FLANGE_BOX_1",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/24e3e966f3a499918cc64dce88fe3a8a6d8b5d45.png"
            ],
            "uom": "NOS",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "FLANGE_BOX",
                "_id": "69c6d7c517dee0c334899a14"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 5,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a17"
                }
            },
            "_id": "69c6d7c517dee0c334899a16",
            "name": "FLANGE BOX-2",
            "materialCode": "FLANGE_BOX_2",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/eebb99c642df149e0eb69a31933527032bb77a76.png"
            ],
            "uom": "NOS",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "FLANGE_BOX",
                "_id": "69c6d7c517dee0c334899a18"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 6,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a1b"
                }
            },
            "_id": "69c6d7c517dee0c334899a1a",
            "name": "FLANGE BOX-3",
            "materialCode": "FLANGE_BOX_3",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/e0d732b2216b9bb5927a263b1183032cfdb79e45.png"
            ],
            "uom": "NOS",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "FLANGE_BOX",
                "_id": "69c6d7c517dee0c334899a1c"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 7,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "length",
                        "label": "Length",
                        "role": "LENGTH",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a1f"
                }
            },
            "_id": "69c6d7c517dee0c334899a1e",
            "name": "FLANGE BOX-4",
            "materialCode": "FLANGE_BOX_4",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/2a4fa194118dcadfb7af23a6361ca791ff8b720f.png",
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/1754c1883ebc87757c23bc7c603b4ceb9a219102.png"
            ],
            "uom": "NOS",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "FLANGE_BOX",
                "_id": "69c6d7c517dee0c334899a20"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 8,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "circumference",
                        "label": "Circumference",
                        "role": "CIRCUMFERENCE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "length",
                        "label": "Length",
                        "role": "LENGTH",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "lengthUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "lengthUom": "MM",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a23"
                }
            },
            "_id": "69c6d7c517dee0c334899a22",
            "name": "NOZZLE",
            "materialCode": "NOZZLE",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/75d7a3bb84eed7086d8e21de1cbb65d852a8ffde.png",
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/58effa2027618ef0d354c24522d8c5baa9445fb0.png"
            ],
            "uom": "NOS",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "NOZZLE",
                "_id": "69c6d7c517dee0c334899a24"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 9,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "area",
                        "label": "Area",
                        "role": "AREA",
                        "type": "NUMBER",
                        "unitType": "AREA",
                        "required": true,
                        "dropdown": "areaUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "geometryMode": [
                        "DIAMETER",
                        "CIRCUMFERENCE"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ],
                    "areaUom": [
                        "M2",
                        "FT2"
                    ],
                    "qtyUom": [
                        "NOS",
                        "SET",
                        "PAIR"
                    ]
                },
                "defaults": {
                    "areaUom": "M2",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c334899a27"
                }
            },
            "_id": "69c6d7c517dee0c334899a26",
            "name": "PATCH",
            "materialCode": "PATCH",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-EQUIP/Frame 47.png"
            ],
            "uom": "M2",
            "designation": "equipment",
            "calculationType": "AREA",
            "calculationConfig": {
                "formulaType": "PATCH",
                "_id": "69c6d7c517dee0c334899a28"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 10,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "MTR"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999d3"
                }
            },
            "_id": "69c6d7c517dee0c3348999d2",
            "name": "PIPE",
            "materialCode": "PIPE",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-pipe.png"
            ],
            "uom": "MTR",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 1,
                "large": 1,
                "_id": "69c6d7c517dee0c3348999d4"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 0,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.229Z",
            "updatedAt": "2026-03-27T19:17:25.229Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999d7"
                }
            },
            "_id": "69c6d7c517dee0c3348999d6",
            "name": "ELBOW 90°",
            "materialCode": "ELBOW_90",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-90.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999d8"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 1,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999db"
                }
            },
            "_id": "69c6d7c517dee0c3348999da",
            "name": "ELBOW 45°",
            "materialCode": "ELBOW_45",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-45.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.3424,
                "large": 0.9,
                "_id": "69c6d7c517dee0c3348999dc"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 2,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999df"
                }
            },
            "_id": "69c6d7c517dee0c3348999de",
            "name": "TEE",
            "materialCode": "TEE",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-tee.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.6,
                "large": 1.8,
                "_id": "69c6d7c517dee0c3348999e0"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 3,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999e3"
                }
            },
            "_id": "69c6d7c517dee0c3348999e2",
            "name": "REDUCER",
            "materialCode": "REDUCER",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-reducer.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.3424,
                "large": 0.9,
                "_id": "69c6d7c517dee0c3348999e4"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 4,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999e7"
                }
            },
            "_id": "69c6d7c517dee0c3348999e6",
            "name": "CAP",
            "materialCode": "CAP",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/insu-cap.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.1712,
                "large": 0.45,
                "_id": "69c6d7c517dee0c3348999e8"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 5,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999eb"
                }
            },
            "_id": "69c6d7c517dee0c3348999ea",
            "name": "INSULATED FLANGE PAIR (REMOVABLE)",
            "materialCode": "FLANGE_PAIR_REMOVABLE",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/abd6b1291c560594d820d4a5ed46cf8d150f0614.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999ec"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 6,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999ef"
                }
            },
            "_id": "69c6d7c517dee0c3348999ee",
            "name": "INSULATED FLANGE VALVE (REMOVABLE)",
            "materialCode": "FLANGE_VALVE_REMOVABLE",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/c0d4725fbbb68d50a9ce3e0b555445b49fa068ae.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999f0"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 7,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999f3"
                }
            },
            "_id": "69c6d7c517dee0c3348999f2",
            "name": "INSULATED FLANGE PAIR (FIXED)",
            "materialCode": "FLANGE_PAIR_FIXED",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/dbf8e5e665679ee238aff1052d297f5722b70c07.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999f4"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 8,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999f7"
                }
            },
            "_id": "69c6d7c517dee0c3348999f6",
            "name": "INSULATED FLANGE VALVE (FIXED)",
            "materialCode": "FLANGE_VALVE_FIXED",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/08702923d0cb614cb884419e94d961d6d3ea2ba8.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999f8"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 9,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        },
        {
            "fieldConfig": {
                "fields": [
                    {
                        "key": "size",
                        "label": "Size",
                        "role": "SIZE",
                        "type": "NUMBER",
                        "unitType": "LENGTH",
                        "required": true,
                        "dropdown": "sizeUom",
                        "isUserAdded": false
                    },
                    {
                        "key": "quantity",
                        "label": "Quantity",
                        "role": "QUANTITY",
                        "type": "NUMBER",
                        "unitType": "COUNT",
                        "required": true,
                        "dropdown": "qtyUom",
                        "isUserAdded": false
                    }
                ],
                "unitDropdowns": {
                    "sizeUom": [
                        "INCH",
                        "MM"
                    ],
                    "qtyUom": [
                        "NOS",
                        "MTR",
                        "FT",
                        "MM",
                        "SET",
                        "PAIR"
                    ],
                    "lengthUom": [
                        "MM",
                        "MTR",
                        "FT",
                        "INCH"
                    ]
                },
                "defaults": {
                    "sizeUom": "INCH",
                    "qtyUom": "NOS"
                },
                "ui": {
                    "allowRename": true,
                    "allowCustomUom": true,
                    "allowUserFields": true,
                    "allowGeometrySwitch": false,
                    "_id": "69c6d7c517dee0c3348999fb"
                }
            },
            "_id": "69c6d7c517dee0c3348999fa",
            "name": "INSULATED WELDED VALVE (FIXED)",
            "materialCode": "WELDED_VALVE_FIXED",
            "image": [
                "https://be-vayuxi-chi.vercel.app/DPR-INSULATION-PIPE/223a0b3dc400f24d148abb8ccd74933d7d46caad.png"
            ],
            "uom": "NOS",
            "designation": "piping",
            "calculationType": "COUNT",
            "isConstants": {
                "small": 0.5,
                "large": 1.5,
                "_id": "69c6d7c517dee0c3348999fc"
            },
            "siteId": {
                "_id": "69c6d6bd17dee0c3348997f7",
                "siteName": "boq insaultion 3",
                "address": "Plot No. 42, Industrial Area, Bangalore, Karnataka, India",
                "contactPerson": "Rajesh Sharma",
                "gstNo": "24AACVBHTY9",
                "phoneNumber": "9876543210",
                "emailId": "rajesh.sharma@abcconstructions.com",
                "documentDate": "2025-06-02T00:00:00.000Z",
                "documentNumber": "DOC123456789",
                "isDeleted": false,
                "company": "6866a5c16f2e1c23be77adf9",
                "type": "insulation_work",
                "createdByType": "user",
                "createdByUser": "6866a5c16f2e1c23be77adfb",
                "createdByManpower": null,
                "createdAt": "2026-03-27T19:13:01.326Z",
                "updatedAt": "2026-03-27T19:13:01.326Z"
            },
            "company": {
                "_id": "6866a5c16f2e1c23be77adf9",
                "name": "anant engineering erp",
                "__v": 0,
                "logo": "https://vayuxi-erp.s3.eu-north-1.amazonaws.com/team-leads/1760003910138-company.jpg",
                "accountNumber": "N/A",
                "bankName": "N/A",
                "branch": "N/A",
                "digitalSignature": "N/A",
                "ifscCode": "N/A",
                "panNumber": "N/A"
            },
            "isDefault": true,
            "isDeleted": false,
            "displayOrder": 10,
            "createdBy": "6866a5c16f2e1c23be77adfb",
            "createdAt": "2026-03-27T19:17:25.230Z",
            "updatedAt": "2026-03-27T19:17:25.230Z"
        }
    ],
    "count": 22
}
```

**Save**: Material IDs for field configuration testing

---

### Step 4: Update Field Configuration (Optional - Test Dynamic Labels)

**Endpoint**: `PUT /api/v1/insulation-dpr-setup/materials/:materialId/field-config`

**Example**: Rename "Size" to "Pipe Diameter"

**cURL**:
```bash
curl --location --request PUT 'http://localhost:3000/api/v1/insulation-dpr-setup/materials/MATERIAL_ID_1/field-config' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "fieldUpdates": [
    {
      "fieldKey": "size",
      "newLabel": "Pipe Diameter"
    },
    {
      "fieldKey": "quantity",
      "newLabel": "Length"
    }
  ]
}'
```

**Response**:
```json
{
  "success": true,
  "message": "Field configuration updated successfully",
  "material": {
    "_id": "MATERIAL_ID_1",
    "fieldConfig": {
      "fields": [
        {
          "key": "size",
          "label": "Pipe Diameter",
          "role": "SIZE"
        },
        {
          "key": "quantity",
          "label": "Length",
          "role": "QUANTITY"
        }
      ]
    }
  }
}
```

---

### Step 5: Add Custom Field (Optional - Test Custom Fields)

**Endpoint**: `POST /api/v1/insulation-dpr-setup/materials/:materialId/custom-field`

**Example**: Add "Insulation Thickness" field

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/insulation-dpr-setup/materials/MATERIAL_ID_1/custom-field' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "fieldDef": {
    "key": "insulation_thickness",
    "label": "Insulation Thickness",
    "type": "NUMBER",
    "unitType": "LENGTH",
    "required": false,
    "dropdown": "lengthUom"
  }
}'
```

**Response**:
```json
{
  "success": true,
  "message": "Custom field added successfully",
  "material": {
    "_id": "MATERIAL_ID_1",
    "fieldConfig": {
      "fields": [
        {
          "key": "size",
          "label": "Pipe Diameter",
          "role": "SIZE"
        },
        {
          "key": "quantity",
          "label": "Length",
          "role": "QUANTITY"
        },
        {
          "key": "insulation_thickness",
          "label": "Insulation Thickness",
          "role": "CUSTOM",
          "type": "NUMBER",
          "unitType": "LENGTH",
          "required": false,
          "dropdown": "lengthUom",
          "isUserAdded": true
        }
      ]
    }
  }
}
```

---

### Step 6: Create Team

**Endpoint**: `POST /api/v1/site/:siteId/team`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "teamName": "Insulation Team A",
  "members": []
}'
```

**Response**:
```json
{
  "success": true,
  "team": {
    "_id": "TEAM_ID",
    "teamName": "Insulation Team A",
    "site": "SITE_ID"
  }
}
```

**Save**: `TEAM_ID` for DPR creation

---

### Step 7: Create DPR - Piping (Legacy Format - Backward Compatible)

**Endpoint**: `POST /api/v1/site/:siteId/team/:teamId/dpr-insulation`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "designation": "piping",
  "layer": "single",
  "legging_material_1": "LRB",
  "legging_thickness_1": 50,
  "cladding_material": "Aluminium",
  "cladding_swg": 24,
  "piping_materials": [
    {
      "name": "PIPE",
      "size": 4,
      "sizeUom": "INCH",
      "qty": 100,
      "uom": "MTR"
    },
    {
      "name": "ELBOW 90°",
      "size": 4,
      "sizeUom": "INCH",
      "qty": 10,
      "uom": "NOS"
    }
  ]
}'
```

**Response**:
```json
{
  "success": true,
  "dpr": {
    "_id": "DPR_ID_1",
    "designation": "piping",
    "layer": "single",
    "piping_materials": [
      {
        "_id": "MAT_1",
        "name": "PIPE",
        "materialCode": "PIPE",
        "size": 4,
        "sizeUom": "INCH",
        "qty": 100,
        "total_area": 100,
        "layer_1_area": 100
      },
      {
        "_id": "MAT_2",
        "name": "ELBOW 90°",
        "materialCode": "ELBOW_90",
        "size": 4,
        "sizeUom": "INCH",
        "qty": 10,
        "total_area": 15
      }
    ],
    "layer_1_rate": 450,
    "layer_1_cost": 51750,
    "totalAmount": 51750
  }
}
```

**Save**: `DPR_ID_1` for updates and sheet generation

---

### Step 8: Create DPR - Equipment (New Dynamic Format)

**Endpoint**: `POST /api/v1/site/:siteId/team/:teamId/dpr-insulation`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "designation": "equipment",
  "layer": "single",
  "legging_material_1": "LRB",
  "legging_thickness_1": 50,
  "cladding_material": "Aluminium",
  "cladding_swg": 24,
  "equipment_materials": [
    {
      "name": "SHELL",
      "materialCode": "SHELL",
      "fieldValues": {
        "length": 5000,
        "lengthUom": "MM",
        "geometryMode": "DIAMETER",
        "diameter": 2000,
        "diameterUom": "MM",
        "quantity": 1,
        "qtyUom": "NOS"
      }
    },
    {
      "name": "DOME",
      "materialCode": "DOME",
      "fieldValues": {
        "circumference": 6280,
        "circumferenceUom": "MM",
        "z_height": 500,
        "z_heightUom": "MM",
        "quantity": 2,
        "qtyUom": "NOS"
      }
    }
  ]
}'
```

**Response**:
```json
{
  "success": true,
  "dpr": {
    "_id": "DPR_ID_2",
    "designation": "equipment",
    "layer": "single",
    "equipment_materials": [
      {
        "_id": "MAT_3",
        "name": "SHELL",
        "materialCode": "SHELL",
        "fieldValues": {
          "length": 5000,
          "lengthUom": "MM",
          "diameter": 2000,
          "diameterUom": "MM",
          "quantity": 1,
          "qtyUom": "NOS"
        },
        "constant": 0,
        "total_area": 31.4,
        "layer_1_area": 31.4
      },
      {
        "_id": "MAT_4",
        "name": "DOME",
        "materialCode": "DOME",
        "fieldValues": {
          "circumference": 6280,
          "circumferenceUom": "MM",
          "z_height": 500,
          "z_heightUom": "MM",
          "quantity": 2,
          "qtyUom": "NOS"
        },
        "constant": 1.27,
        "total_area": 7.96,
        "layer_1_area": 7.96
      }
    ],
    "layer_1_rate": 850,
    "layer_1_cost": 33456,
    "totalAmount": 33456
  }
}
```

**Save**: `DPR_ID_2` for sheet generation

---

### Step 9: Update DPR (Test Dynamic Field Updates)

**Endpoint**: `POST /api/v1/insulation-update-dpr/:dprId`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/insulation-update-dpr/DPR_ID_2' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "equipment_materials": [
    {
      "_id": "MAT_3",
      "name": "SHELL",
      "materialCode": "SHELL",
      "fieldValues": {
        "length": 6000,
        "lengthUom": "MM",
        "diameter": 2500,
        "diameterUom": "MM",
        "quantity": 1,
        "qtyUom": "NOS"
      }
    }
  ]
}'
```

**Response**:
```json
{
  "success": true,
  "dpr": {
    "_id": "DPR_ID_2",
    "equipment_materials": [
      {
        "_id": "MAT_3",
        "name": "SHELL",
        "materialCode": "SHELL",
        "fieldValues": {
          "length": 6000,
          "lengthUom": "MM",
          "diameter": 2500,
          "diameterUom": "MM"
        },
        "total_area": 47.1
      }
    ],
    "totalAmount": 40035
  }
}
```

---

### Step 10: Generate Measurement Sheet (Excel)

**Endpoint**: `GET /api/v1/site/:siteId/team/:teamId/dpr-insulation/measurement-sheet`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation/measurement-sheet?designation=equipment' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--output 'measurement_sheet.xlsx'
```

**Response**: Excel file downloaded

**Sheet Headers** (Dynamic based on fieldConfig):
- Material Name
- Pipe Diameter (renamed from Size)
- Length (renamed from Quantity)
- Unit
- Layer 1 Area
- Layer 2 Area
- Layer 3 Area
- Total Area
- Rate
- Amount

---

### Step 11: Generate Abstract Sheet (Excel)

**Endpoint**: `GET /api/v1/site/:siteId/team/:teamId/dpr-insulation/abstract-sheet`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation/abstract-sheet?designation=equipment' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--output 'abstract_sheet.xlsx'
```

**Response**: Excel file with summary

---

### Step 12: Generate Invoice Sheet (Excel)

**Endpoint**: `GET /api/v1/site/:siteId/team/:teamId/dpr-insulation/invoice-sheet`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation/invoice-sheet?designation=equipment' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--output 'invoice_sheet.xlsx'
```

**Response**: Excel file with invoice details

---

### Step 13: Generate PDF (All Sheets Combined)

**Endpoint**: `POST /api/v1/site/:siteId/team/:teamId/dpr-insulation/generate-pdf`

**cURL**:
```bash
curl --location 'http://localhost:3000/api/v1/site/SITE_ID/team/TEAM_ID/dpr-insulation/generate-pdf' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_JWT_TOKEN' \
--data '{
  "designation": "equipment",
  "includeSheets": ["measurement", "abstract", "invoice"]
}' \
--output 'complete_dpr.pdf'
```

**Response**: PDF file downloaded

---

## Quick Test Script (All Steps Combined)

```bash
#!/bin/bash

# Configuration
BASE_URL="http://localhost:3000"
TOKEN="YOUR_JWT_TOKEN"
COMPANY_ID="YOUR_COMPANY_ID"

# Step 1: Create Site
echo "Creating site..."
SITE_RESPONSE=$(curl -s --location "${BASE_URL}/api/v1/site" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer ${TOKEN}" \
--data "{
  \"siteName\": \"Dynamic Insulation Test Site\",
  \"address\": \"Test Address\",
  \"company\": \"${COMPANY_ID}\"
}")

SITE_ID=$(echo $SITE_RESPONSE | jq -r '.site._id')
echo "Site created: $SITE_ID"

# Step 2: Upload Rates
echo "Uploading rates..."
curl -s --location "${BASE_URL}/api/v1/site/${SITE_ID}/rate/upload-csv" \
--header "Authorization: Bearer ${TOKEN}" \
--form 'file=@"insulation_rates.csv"' \
--form 'workType="insulation_work"'

# Step 3: Get Materials
echo "Fetching materials..."
MATERIALS=$(curl -s --location "${BASE_URL}/api/v1/insulation-dpr-setup/materials?siteId=${SITE_ID}" \
--header "Authorization: Bearer ${TOKEN}")

echo "Materials initialized with dynamic configs!"

# Step 4: Create Team
echo "Creating team..."
TEAM_RESPONSE=$(curl -s --location "${BASE_URL}/api/v1/site/${SITE_ID}/team" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer ${TOKEN}" \
--data '{
  "teamName": "Test Team"
}')

TEAM_ID=$(echo $TEAM_RESPONSE | jq -r '.team._id')
echo "Team created: $TEAM_ID"

# Step 5: Create DPR
echo "Creating DPR..."
DPR_RESPONSE=$(curl -s --location "${BASE_URL}/api/v1/site/${SITE_ID}/team/${TEAM_ID}/dpr-insulation" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer ${TOKEN}" \
--data '{
  "designation": "equipment",
  "layer": "single",
  "legging_material_1": "LRB",
  "legging_thickness_1": 50,
  "cladding_material": "Aluminium",
  "cladding_swg": 24,
  "equipment_materials": [
    {
      "name": "SHELL",
      "materialCode": "SHELL",
      "fieldValues": {
        "length": 5000,
        "lengthUom": "MM",
        "diameter": 2000,
        "diameterUom": "MM",
        "quantity": 1,
        "qtyUom": "NOS"
      }
    }
  ]
}')

DPR_ID=$(echo $DPR_RESPONSE | jq -r '.dpr._id')
echo "DPR created: $DPR_ID"

# Step 6: Generate Sheet
echo "Generating measurement sheet..."
curl --location "${BASE_URL}/api/v1/site/${SITE_ID}/team/${TEAM_ID}/dpr-insulation/measurement-sheet?designation=equipment" \
--header "Authorization: Bearer ${TOKEN}" \
--output "measurement_${DPR_ID}.xlsx"

echo "Complete! Check measurement_${DPR_ID}.xlsx"
```

---

## Postman Collection

Import this JSON into Postman:

```json
{
  "info": {
    "name": "Dynamic Insulation DPR - Complete Workflow",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000"
    },
    {
      "key": "token",
      "value": "YOUR_JWT_TOKEN"
    },
    {
      "key": "companyId",
      "value": "YOUR_COMPANY_ID"
    },
    {
      "key": "siteId",
      "value": ""
    },
    {
      "key": "teamId",
      "value": ""
    },
    {
      "key": "dprId",
      "value": ""
    },
    {
      "key": "materialId",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "1. Create Site",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.collectionVariables.set('siteId', pm.response.json().site._id);"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"siteName\": \"Dynamic Insulation Test Site\",\n  \"address\": \"Test Address\",\n  \"company\": \"{{companyId}}\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/site",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "site"]
        }
      }
    },
    {
      "name": "2. Upload Rates",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "file",
              "type": "file",
              "src": "/path/to/insulation_rates.csv"
            },
            {
              "key": "workType",
              "value": "insulation_work",
              "type": "text"
            }
          ]
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/site/{{siteId}}/rate/upload-csv",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "site", "{{siteId}}", "rate", "upload-csv"]
        }
      }
    },
    {
      "name": "3. Get Setup Materials",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.collectionVariables.set('materialId', pm.response.json().materials[0]._id);"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/api/v1/insulation-dpr-setup/materials?siteId={{siteId}}",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "insulation-dpr-setup", "materials"],
          "query": [
            {
              "key": "siteId",
              "value": "{{siteId}}"
            }
          ]
        }
      }
    },
    {
      "name": "4. Update Field Config",
      "request": {
        "method": "PUT",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"fieldUpdates\": [\n    {\n      \"fieldKey\": \"size\",\n      \"newLabel\": \"Pipe Diameter\"\n    }\n  ]\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/insulation-dpr-setup/materials/{{materialId}}/field-config",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "insulation-dpr-setup", "materials", "{{materialId}}", "field-config"]
        }
      }
    },
    {
      "name": "5. Add Custom Field",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"fieldDef\": {\n    \"key\": \"thickness\",\n    \"label\": \"Insulation Thickness\",\n    \"type\": \"NUMBER\",\n    \"unitType\": \"LENGTH\",\n    \"required\": false,\n    \"dropdown\": \"lengthUom\"\n  }\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/insulation-dpr-setup/materials/{{materialId}}/custom-field",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "insulation-dpr-setup", "materials", "{{materialId}}", "custom-field"]
        }
      }
    },
    {
      "name": "6. Create Team",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.collectionVariables.set('teamId', pm.response.json().team._id);"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"teamName\": \"Test Team\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/site/{{siteId}}/team",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "site", "{{siteId}}", "team"]
        }
      }
    },
    {
      "name": "7. Create DPR - Equipment (Dynamic)",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.collectionVariables.set('dprId', pm.response.json().dpr._id);"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"designation\": \"equipment\",\n  \"layer\": \"single\",\n  \"legging_material_1\": \"LRB\",\n  \"legging_thickness_1\": 50,\n  \"cladding_material\": \"Aluminium\",\n  \"cladding_swg\": 24,\n  \"equipment_materials\": [\n    {\n      \"name\": \"SHELL\",\n      \"materialCode\": \"SHELL\",\n      \"fieldValues\": {\n        \"length\": 5000,\n        \"lengthUom\": \"MM\",\n        \"diameter\": 2000,\n        \"diameterUom\": \"MM\",\n        \"quantity\": 1,\n        \"qtyUom\": \"NOS\"\n      }\n    }\n  ]\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/site/{{siteId}}/team/{{teamId}}/dpr-insulation",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "site", "{{siteId}}", "team", "{{teamId}}", "dpr-insulation"]
        }
      }
    },
    {
      "name": "8. Update DPR",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"equipment_materials\": [\n    {\n      \"name\": \"SHELL\",\n      \"materialCode\": \"SHELL\",\n      \"fieldValues\": {\n        \"length\": 6000,\n        \"lengthUom\": \"MM\",\n        \"diameter\": 2500,\n        \"diameterUom\": \"MM\",\n        \"quantity\": 1,\n        \"qtyUom\": \"NOS\"\n      }\n    }\n  ]\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/insulation-update-dpr/{{dprId}}",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "insulation-update-dpr", "{{dprId}}"]
        }
      }
    },
    {
      "name": "9. Generate Measurement Sheet",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/api/v1/site/{{siteId}}/team/{{teamId}}/dpr-insulation/measurement-sheet?designation=equipment",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "site", "{{siteId}}", "team", "{{teamId}}", "dpr-insulation", "measurement-sheet"],
          "query": [
            {
              "key": "designation",
              "value": "equipment"
            }
          ]
        }
      }
    }
  ]
}
```

---

## Testing Checklist

### Phase 1: Setup
- [ ] Site created successfully
- [ ] Rates uploaded (CSV)
- [ ] Default materials initialized with fieldConfig
- [ ] Materials have materialCode, isConstants, calculationConfig

### Phase 2: Field Configuration
- [ ] Get materials shows dynamic fieldConfig
- [ ] Update field labels works
- [ ] Custom fields can be added
- [ ] Field configurations persist

### Phase 3: DPR Creation
- [ ] Team created successfully
- [ ] Piping DPR created (legacy format)
- [ ] Equipment DPR created (dynamic format with fieldValues)
- [ ] Calculations are correct
- [ ] materialCode is stored

### Phase 4: DPR Updates
- [ ] DPR can be updated with new fieldValues
- [ ] Calculations recalculate correctly
- [ ] Unit conversions work

### Phase 5: Sheet Generation
- [ ] Measurement sheet generates
- [ ] Dynamic headers appear (renamed fields)
- [ ] Abstract sheet generates
- [ ] Invoice sheet generates
- [ ] PDF generation works

---

## Expected Results

### Material Initialization
- 11 piping materials with full fieldConfig
- 11 equipment materials with full fieldConfig
- Each material has materialCode, isConstants (piping), calculationConfig (equipment)

### DPR Creation
- Backward compatible with old format
- New format with fieldValues supported
- Calculations accurate for both formats

### Sheet Generation
- Headers reflect renamed field labels
- Custom fields appear in sheets
- All calculations correct

---

## Troubleshooting

### Issue: Materials not initialized
**Solution**: Ensure workType is exactly `"insulation_work"` in rate upload

### Issue: Field config not updating
**Solution**: Check materialId is correct and material exists

### Issue: DPR calculations incorrect
**Solution**: Verify fieldValues include units (e.g., lengthUom, diameterUom)

### Issue: Sheets not generating
**Solution**: Ensure DPR has materials and designation is correct

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-24 10:30 PM IST  
**Status**: Complete API Workflow Ready for Testing
