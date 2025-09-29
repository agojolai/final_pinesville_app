# Reports & Tickets System Implementation

This document provides a complete overview of the implemented reports and tickets system with Firestore integration.

## Architecture Overview

The system follows a clean architecture pattern with proper separation of concerns:

```
lib/src/features/support/
├── data/
│   ├── models/
│   │   └── report_model.dart          # Data models with Firestore mapping
│   └── repositories/
│       └── report_repository.dart     # Repository pattern for data access
└── presentation/
    ├── reports_tickets_screen.dart    # Main reports list screen
    ├── submit_report_screen.dart      # Report submission form
    ├── report_detail_screen.dart      # Detailed report view with feedback
    └── admin_report_testing_screen.dart # Admin utilities for testing
```

## Data Models

### ReportModel
Complete report model matching the Firestore structure:
- **Fields**: id, unitNumber, category, subCategory, description, status, timestamps
- **Relationships**: tenant info, attachments, updates, feedback
- **Methods**: JSON serialization/deserialization, copyWith for immutability

### Supporting Models
- **TenantInfo**: User identification and display name
- **ReportUpdate**: Admin messages and status updates with timestamps
- **ReportFeedback**: Rating and comment system for resolved reports

## Repository Layer (ReportRepository)

### Core Operations
- `submitReport()`: Create new reports with file upload
- `getTenantReports()`: Fetch user-specific reports
- `getAllReports()`: Admin function for complete report list
- `getReportById()`: Single report retrieval

### Real-time Features
- `streamTenantReports()`: Live updates for user reports
- `streamAllReports()`: Live updates for admin dashboard

### Admin Operations
- `updateReportStatus()`: Change report status with automatic timestamps
- `addReportUpdate()`: Add messages/updates to existing reports
- `addReportFeedback()`: Handle tenant feedback submission

### File Management
- Firebase Storage integration for photo/video attachments
- Organized storage structure: `/reports/{reportId}/{filename}`
- Automatic file naming with timestamps
- Support for multiple file formats (images, videos)

### Testing Utilities
- `createSampleReports()`: Generate test data
- `deleteAllReports()`: Clean up for testing

## User Interface Components

### 1. Reports & Tickets Screen (`reports_tickets_screen.dart`)
**Features:**
- Real-time report list with loading/error states
- Status-based filtering and statistics header
- Pull-to-refresh functionality
- Admin tools access via settings menu

**States Handled:**
- Loading state with progress indicator
- Error state with retry functionality
- Empty state with call-to-action
- Populated list with proper formatting

### 2. Submit Report Screen (`submit_report_screen.dart`)
**Features:**
- Category/subcategory dropdown selection
- Rich text description input with validation
- Photo/video attachment support (up to 5 files)
- Real Firestore integration with progress indicators

**File Upload:**
- Camera capture or gallery selection
- Image compression (1920x1080, 85% quality)
- Video duration limits (5 minutes)
- Firebase Storage upload with progress

### 3. Report Detail Screen (`report_detail_screen.dart`)
**Features:**
- Complete report information display
- Attachment viewing capabilities
- Timeline of updates and status changes
- Feedback system for resolved reports

**Feedback System:**
- 1-5 star rating with visual feedback
- Optional comment field (500 character limit)
- Existing feedback display
- Integration with repository for persistence

### 4. Admin Testing Screen (`admin_report_testing_screen.dart`)
**Features:**
- Complete report management interface
- Status update functionality
- Message/update addition
- Statistics dashboard
- Sample data creation/deletion

## Firestore Data Structure

```javascript
// Collection: /reports/{reportId}
{
  "id": "R001",
  "unitNumber": "204-B",
  "category": "Maintenance / Repairs", 
  "subCategory": "Plumbing (leaks, clogs, water issues)",
  "description": "Kitchen sink is clogged and water is backing up",
  "status": "inProgress",
  "submittedAt": "2024-09-15T10:00:00Z",
  "resolvedAt": "2024-09-17T14:00:00Z",
  "tenant": {
    "userId": "uid_abc123",
    "name": "Caleb Anderson"
  },
  "attachments": [
    "https://storage.googleapis.com/your-bucket/reports/R001/photo1.jpg"
  ],
  "updates": [
    {
      "message": "Report received. Maintenance team has been notified.",
      "timestamp": "2024-09-15T10:05:00Z",
      "isAdmin": true
    }
  ],
  "feedback": {
    "rating": 5,
    "comment": "Quick and professional service!"
  }
}
```

## Firebase Storage Structure

```
/reports/
  /{reportId}/
    /R001_attachment_1_1634567890123.jpg
    /R001_attachment_2_1634567890124.mp4
    /R001_attachment_3_1634567890125.jpg
```

## How to Use the System

### For Tenants:
1. **Submit Report**: Access via Reports & Tickets screen → floating action button
2. **Track Progress**: View real-time status updates and admin messages
3. **Provide Feedback**: Rate service quality for resolved reports
4. **View Attachments**: Access uploaded photos/videos in detail view

### For Administrators:
1. **Access Admin Tools**: Settings icon in reports screen header
2. **Manage Reports**: Use Admin Report Testing screen for status updates
3. **Add Updates**: Send messages to tenants about progress
4. **Generate Test Data**: Create sample reports for testing
5. **Monitor Statistics**: View report counts by status

### For Developers:
1. **Testing**: Use admin utilities to create/delete sample data
2. **Monitoring**: Check Firestore console for data structure
3. **File Management**: Monitor Firebase Storage for attachment uploads
4. **Error Handling**: Observe proper error states and user feedback

## Error Handling

The system includes comprehensive error handling for:
- **Network Connectivity**: Offline scenarios and timeout handling
- **Firebase Errors**: Authentication, permission, and quota issues
- **File Upload Failures**: Storage errors, file size limits, format validation
- **User Input Validation**: Required fields, character limits, file constraints
- **Loading States**: Proper UI feedback during async operations

## Security Considerations

- **Authentication Required**: All operations require valid Firebase Auth user
- **User Isolation**: Tenants can only access their own reports
- **Admin Functions**: Restricted to authorized users (implement role-based access)
- **File Upload Validation**: Type and size restrictions on attachments
- **Input Sanitization**: Proper validation of all user inputs

## Future Enhancements

Potential improvements for the system:
1. **Push Notifications**: Real-time alerts for status changes
2. **Role-Based Access Control**: Proper admin/tenant permission system
3. **Advanced Filtering**: Date ranges, categories, status combinations
4. **Export Functionality**: PDF generation for reports
5. **Analytics Dashboard**: Reporting metrics and trends
6. **Batch Operations**: Multiple report management
7. **Integration APIs**: Connect with external maintenance systems

## Testing the Implementation

1. **Create Sample Data**: Use admin screen to generate test reports
2. **Submit New Report**: Test the complete submission workflow
3. **Update Status**: Use admin tools to change report status
4. **Add Messages**: Test the update/messaging system
5. **Submit Feedback**: Rate a resolved report
6. **File Upload**: Test photo/video attachment functionality
7. **Real-time Updates**: Test live data synchronization

The system is now fully functional and ready for production use with proper Firebase configuration and user authentication setup.