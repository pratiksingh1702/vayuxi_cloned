# P&M Entry Flow Plan

## Scope

This document defines the APK P&M Entry flow for Erection and Fabrication users. The APK should use the same structure-specific P&M backend flow used by the web application.

## End-To-End User Journey

1. User opens the selected work type, such as Erection or Fabrication.
2. User opens Daily Entry.
3. User selects P&M Entry.
4. User selects a site.
5. APK loads P&M setup resources for that site.
6. User selects a P&M category.
7. User selects an equipment or work item.
8. User enters daily P&M data.
9. User saves the entry.
10. Saved data appears in P&M Reports and is available for Detailed DPR + P&M reporting.

## Setup Dependency

P&M Entry depends on P&M Setup.

Before performing entry:

- The site must exist.
- P&M setup resources must exist for that site.
- Default resources should load from backend master data.
- Custom user-created resources should appear along with defaults.
- Duplicate cards should not be shown even if the backend sends repeated resources.

## Data Flow

P&M Setup uses:

- `GET /site/:siteId/structure-work/pm-resources`
- `POST /site/:siteId/structure-work/pm-resources`
- `PUT /site/:siteId/structure-work/pm-resources/:resourceId`
- `DELETE /site/:siteId/structure-work/pm-resources/:resourceId`

P&M Entry uses:

- `GET /site/:siteId/structure-work/pm-entry?date=YYYY-MM-DD`
- `POST /site/:siteId/structure-work/pm-entry`

Reports use the same saved P&M data through:

- P&M Reports screen
- Detailed DPR + P&M combined report

## Entry Fields

Minimum entry fields:

- Date
- Selected equipment/resource
- Actual quantity
- Remarks

Optional display fields:

- Equipment number
- Capacity
- Unit
- Image
- Category

## Validation Logic

- Equipment/resource selection is required.
- Actual quantity must be numeric.
- Remarks are optional.
- Date defaults to today but can be changed.
- If no P&M setup exists, show setup-required empty state.
- If no equipment exists in a category, show an empty category state.

## DPR And Report Dependency

P&M Entry does not change DPR Entry progress directly.

The linkage happens during reporting:

- DPR Entry contributes work progress data.
- Satmax history contributes old date and mark-number data where applicable.
- P&M Entry contributes resource/equipment usage.
- Detailed DPR + P&M combines DPR data with P&M resource data for the selected date range.

## Satmax Behavior

For Satmax users, APK behavior should match web:

- Satmax-specific history upload remains visible only for the configured Satmax user.
- Detailed DPR and Detailed DPR + P&M reports must be available in the APK for structure work flows.
- P&M data saved from APK must use structure P&M endpoints so combined reports can read the same data as web.

## Testing Checklist

1. Login as normal Erection user.
2. Open Setup > P&M Setup.
3. Verify category cards are not duplicated.
4. Add a custom P&M work.
5. Edit the custom work image/details.
6. Open Daily Entry > P&M Entry.
7. Select category and work.
8. Save entry with quantity and remarks.
9. Open P&M Reports and verify saved entry.
10. Login as Satmax user.
11. Verify Satmax history upload is available.
12. Open Reports > DPR Sheets.
13. Verify Detailed DPR and Detailed DPR + P&M are visible for structure work flow.
14. Download Detailed DPR + P&M for a date range with P&M data.
