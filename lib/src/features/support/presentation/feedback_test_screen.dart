import 'package:flutter/material.dart';
import '../../../common/widgets/feedback/feedback.dart';

/// Demo screen to test the feedback widgets
class FeedbackTestScreen extends StatelessWidget {
  const FeedbackTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Widget Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                FeedbackUtils.showFeedbackDialog(
                  context,
                  title: 'Test Dialog',
                  subtitle: 'How was your experience?',
                  onSubmit: (rating, comment) {
                    print('Dialog - Rating: $rating, Comment: $comment');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Feedback submitted: $rating stars'),
                      ),
                    );
                  },
                );
              },
              child: const Text('Test Feedback Dialog'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                FeedbackUtils.showFeedbackBottomSheet(
                  context,
                  title: 'Test Bottom Sheet',
                  subtitle: 'Rate your experience!',
                  onSubmit: (rating, comment) {
                    print('Bottom Sheet - Rating: $rating, Comment: $comment');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Feedback submitted: $rating stars'),
                      ),
                    );
                  },
                );
              },
              child: const Text('Test Feedback Bottom Sheet'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                FeedbackUtils.showFeedback(
                  context,
                  title: 'Auto-Select Format',
                  subtitle: 'Automatically chooses dialog or bottom sheet',
                  onSubmit: (rating, comment) {
                    print('Auto - Rating: $rating, Comment: $comment');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Feedback submitted: $rating stars'),
                      ),
                    );
                  },
                );
              },
              child: const Text('Test Auto-Select Feedback'),
            ),
            
            const SizedBox(height: 40),
            
            StarRatingWidget(
              initialRating: 3,
              onRatingChanged: (rating) {
                print('Inline rating changed: $rating');
              },
            ),
            
            const SizedBox(height: 10),
            
            const Text('^ Standalone Star Rating Widget'),
          ],
        ),
      ),
    );
  }
}
