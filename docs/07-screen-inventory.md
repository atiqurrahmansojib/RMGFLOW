# Document 7 — Complete Screen Inventory

Grouped by module. "List/Detail/Form" pattern implied for most; only unusual screens spelled out in detail.

## Auth & Account
1. Login
2. Forgot/Reset Password
3. Device/Session Management (active sessions, revoke)
4. Profile & Settings (notification preferences)

## Admin (Super Admin / Owner)
5. User List
6. User Create/Edit
7. Role List & Permission Matrix Editor
8. Assignment Manager (user ↔ buyer, user ↔ factory)
9. Master Data: Seasons List/Form
10. Master Data: Currencies & Exchange Rates
11. Master Data: Countries / Incoterms / Payment Terms
12. Master Data: Document Types
13. Master Data: Defect Types
14. Master Data: T&A Milestone Type Library
15. System Audit Log Viewer

## Buyer Management
16. Buyer List (search/filter by status, group, country)
17. Buyer Detail (tabs: Overview, Contacts, T&A Templates, Documents Required, Activity, Performance, Orders)
18. Buyer Create/Edit Form
19. Buyer Contact Create/Edit

## Factory / Vendor Management
20. Factory/Vendor List (filter by type, product category, compliance status)
21. Factory Detail (tabs: Overview, Contacts, Capabilities, Certifications, Buyer Approvals, Orders, Rating/History)
22. Factory Create/Edit Form
23. Factory Contact Create/Edit

## Inquiry
24. Inquiry List (filter by status, buyer, merchandiser)
25. Inquiry Detail (tabs: Overview, Factory Candidates, Costing, Quotation, Activity, Attachments)
26. Inquiry Create/Edit Form
27. Mark Won/Lost Dialog (reason capture)

## Style / Product Development
28. Style List (search by style no., buyer style no., category)
29. Style Detail (tabs: Spec, Revisions, Tech Pack, Reference Images, Linked Samples/Orders)
30. Style Create/Edit Form
31. Style Revision Compare View

## Sampling
32. Sample List (filter by type, status, buyer, style, due date)
33. Sample Detail (tabs: Overview, Revisions, Approval History, Photos/Docs, Courier Tracking)
34. Sample Request Form
35. Sample Submission Update Form (submission date, photos)
36. Sample Approval Response Form (buyer decision capture: approved/rejected/revise + comments)

## Costing
37. Costing List (per style/inquiry, versions)
38. Costing Detail / Version View (component breakdown, margin)
39. Costing Create/Edit Form (component line items)
40. Costing Revision Form (new version referencing prior)
41. Costing Approval Screen

## Quotation
42. Quotation List
43. Quotation Detail / Version View
44. Quotation Create Form (select costing version)
45. Quotation Revision Form
46. Quotation Send/Status Update

## Order Management
47. Order List (filter by status, buyer, factory, delivery date)
48. Order Detail (tabs: Overview, Items/Breakdown, Amendments, T&A, Production, Quality, Shipments, Documents, Financial)
49. Order Create Form (from quotation or direct)
50. Order Amendment Request Form
51. Order Amendment Approval Screen
52. Order Cancellation Form
53. Order Split Form (allocate to multiple factories)

## T&A / Critical Path
54. T&A Template List
55. T&A Template Create/Edit (milestone definitions, dependencies, default offsets)
56. Order T&A Calendar View (Gantt-style critical path)
57. T&A Milestone Update Form (actual date, status, reason)
58. T&A Delay/Alert List

## Production Follow-up
59. Production Dashboard (per order/factory)
60. Daily Production Update Form (cutting/sewing/finishing/packing qty)
61. Production History / Planned-vs-Actual Chart

## Quality
62. Inspection List (filter by type, status, order, factory)
63. Inspection Detail (AQL data, defects, photos)
64. Inspection Create/Edit Form
65. Defect Entry Form
66. CAPA Tracker (list + detail + response form)

## Approval Engine (cross-cutting UI, contextualized per module)
67. Pending Approvals Inbox (role-scoped)
68. Approval Detail/Action Screen (generic, parameterized by target type)
69. Approval History Timeline (embedded in relevant entity detail screens)

## Shipment
70. Shipment List (filter by status, order, ETD/ETA)
71. Shipment Detail (tabs: Overview, Cartons, Documents, Status History)
72. Shipment Create/Edit Form
73. Partial Shipment Authorization Dialog

## Commercial & Documents
74. Document List (per order/shipment)
75. Document Upload Form (type, version, expiry)
76. Document Detail/Preview

## Financial Tracking
77. Order Profitability Detail
78. Receivables List (buyer, due date, status)
79. Payables List (factory, due date, status)
80. Payment Record Form

## Claims & Disputes
81. Claims List
82. Claim Detail / Resolution Form

## Communication & Activity
83. Activity Timeline (embedded component across entity detail screens)
84. Add Activity/Note Form (calls/emails/meetings)

## Tasks
85. My Tasks List
86. Task Create/Edit Form (linked entity picker)
87. Team Task Board (manager view)

## Notifications
88. Notification Center (in-app feed)
89. Notification Preferences

## Dashboards
90. Management Dashboard
91. Merchandiser Dashboard
92. Factory Follow-up Dashboard
93. Quality Dashboard

## Reports
94. Report Catalog (list of available reports by category)
95. Report Viewer (parameterized: buyer, order, production, quality, shipment, financial — per Document 14)

## Search
96. Global Search (results grouped by entity type)

## Common/Shared UI Patterns
97. Empty State (no data) — standard component, every list screen
98. Error State — standard component
99. Offline Banner / Sync Status — standard component
100. Image/Camera Capture Sheet — standard component (samples, production, quality, documents)

**Total: ~100 distinct screens/patterns**, several of which (Approval Detail, Activity Timeline, Attachment Upload, Empty/Error/Offline states) are shared components reused across modules rather than rebuilt per module — consistent with prompt §60 (optimize for workflow correctness, not screen count) and §35 (design system before building dozens of screens, see Document 12 for Flutter component strategy).
