import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/review_model.dart';
import '../theme/app_theme.dart';

class ReviewsManagerView extends StatefulWidget {
  const ReviewsManagerView({super.key});

  @override
  State<ReviewsManagerView> createState() => _ReviewsManagerViewState();
}

class _ReviewsManagerViewState extends State<ReviewsManagerView> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, published, hidden

  final List<Color> _avatarColors = const [
    Color(0xFF1E88E5), // Blue
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
  ];

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final code = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return _avatarColors[code % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allReviews = provider.reviews;

    // Filter
    final filtered = allReviews.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.authorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.authorLocation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.text.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_filterStatus == 'published') return r.isPublished;
      if (_filterStatus == 'hidden') return !r.isPublished;
      return true;
    }).toList();

    final publishedCount = allReviews.where((r) => r.isPublished).length;
    final fiveStarCount = allReviews.where((r) => r.rating == 5).length;
    final avgRating = allReviews.isEmpty
        ? 5.0
        : (allReviews.map((r) => r.rating).reduce((a, b) => a + b) / allReviews.length);

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================= HEADER =======================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Google Reviews & Web Testimonials',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.emerald200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done_rounded, size: 12, color: AppTheme.emerald800),
                                SizedBox(width: 4),
                                Text(
                                  'Live Web Sync',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.emerald800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Input authentic reviews from your Google Business profile and sync them live to the website slider.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (allReviews.isEmpty)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await provider.seedDefaultReviews();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Official Google reviews seeded to Firestore!'),
                                backgroundColor: AppTheme.emeraldGreen,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Seed Official Reviews'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openReviewDialog(context, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Google Review', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ======================= STATS STRIP =======================
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Reviews',
                  value: '${allReviews.length}',
                  subtitle: 'In Admin Database',
                  icon: Icons.reviews_rounded,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Live on Website',
                  value: '$publishedCount',
                  subtitle: 'Currently Sliding',
                  icon: Icons.visibility_rounded,
                  color: AppTheme.emeraldGreen,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Average Rating',
                  value: '${avgRating.toStringAsFixed(1)} / 5.0',
                  subtitle: '$fiveStarCount Five-Star Reviews',
                  icon: Icons.star_rate_rounded,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Google Verification',
                  value: '100% Genuine',
                  subtitle: 'From Google Maps',
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF4285F4),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ======================= FILTER & SEARCH BAR =======================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search reviews by reviewer name, city, or quote...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Chips
                  _buildFilterChip('all', 'All (${allReviews.length})'),
                  const SizedBox(width: 6),
                  _buildFilterChip('published', 'Live on Web ($publishedCount)'),
                  const SizedBox(width: 6),
                  _buildFilterChip('hidden', 'Hidden (${allReviews.length - publishedCount})'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ======================= REVIEWS GRID =======================
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No reviews found',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.slate800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Try adjusting your search query.'
                          : 'Click "Add Google Review" to publish your first customer testimonial.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (allReviews.isEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.seedDefaultReviews(),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Seed 5 Official Reviews'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 1200) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 220,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final review = filtered[idx];
                      return _buildReviewCard(review, provider);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.slate800,
      ),
      selected: isSelected,
      selectedColor: AppTheme.slate900,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = value);
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
                  Text(subtitle, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, AdminProvider provider) {
    final avatarColor = _getAvatarColor(review.authorName);
    final initial = review.authorName.isNotEmpty ? review.authorName.substring(0, 1).toUpperCase() : 'G';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: review.isPublished ? Colors.grey.shade200 : Colors.amber.shade200,
          width: review.isPublished ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Google Logo + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: avatarColor,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.slate900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (review.authorLocation.isNotEmpty)
                      Text(
                        review.authorLocation,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Stars & relative date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.relativeTime,
                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Review Quote Text
          Expanded(
            child: Text(
              '“${review.text}”',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Bottom Action Bar: Published Switch + Edit + Delete
          Row(
            children: [
              // Live Web Toggle
              InkWell(
                onTap: () => provider.toggleReviewPublished(review.id, !review.isPublished),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: review.isPublished ? const Color(0xFFECFDF5) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: review.isPublished ? const Color(0xFFA7F3D0) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: review.isPublished ? const Color(0xFF059669) : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        review.isPublished ? 'Live on Web' : 'Hidden',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: review.isPublished ? const Color(0xFF047857) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.primaryBlue),
                tooltip: 'Edit Review',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(5),
                onPressed: () => _openReviewDialog(context, review),
              ),
              const SizedBox(width: 4),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red),
                tooltip: 'Delete Review',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(5),
                onPressed: () => _confirmDeleteReview(context, review, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================= ADD / EDIT REVIEW DIALOG =======================
  void _openReviewDialog(BuildContext context, ReviewModel? existing) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.authorName ?? '');
    final locCtrl = TextEditingController(text: existing?.authorLocation ?? '');
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    final timeCtrl = TextEditingController(text: existing?.relativeTime ?? '2 weeks ago');
    int rating = existing?.rating ?? 5;
    bool isPublished = existing?.isPublished ?? true;
    bool isVerified = existing?.isVerified ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Google Review' : 'Add Google Review to Web',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reviewer Full Name *',
                        hintText: 'e.g. Priyantha Dissanayake',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location & Time Ago Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Location / City',
                              hintText: 'e.g. Colombo 07, Melbourne AU',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Time / Date *',
                              hintText: 'e.g. 2 weeks ago',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Star Rating Picker
                    Row(
                      children: [
                        const Text('Star Rating:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 12),
                        Row(
                          children: List.generate(5, (index) {
                            final starNum = index + 1;
                            return IconButton(
                              icon: Icon(
                                starNum <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 26,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setDialogState(() => rating = starNum),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text('$rating / 5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Review Text
                    TextField(
                      controller: textCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Review Quote / Text *',
                        hintText: 'Paste or type the exact review as posted by the customer on Google Maps...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Toggles
                    CheckboxListTile(
                      value: isPublished,
                      onChanged: (val) => setDialogState(() => isPublished = val ?? true),
                      title: const Text('Publish Live to Website Slider', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('When checked, this review appears immediately on primelifecare.lk.', style: TextStyle(fontSize: 10.5)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    CheckboxListTile(
                      value: isVerified,
                      onChanged: (val) => setDialogState(() => isVerified = val ?? true),
                      title: const Text('Mark as Google Verified Family', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Displays the Google verification checkmark on the card.', style: TextStyle(fontSize: 10.5)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(isEditing ? 'Save Changes' : 'Publish Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || textCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter reviewer name and review text!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final newReview = ReviewModel(
                    id: existing?.id ?? 'rev_${DateTime.now().millisecondsSinceEpoch}',
                    authorName: nameCtrl.text.trim(),
                    authorLocation: locCtrl.text.trim(),
                    rating: rating,
                    relativeTime: timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : 'Recently',
                    text: textCtrl.text.trim(),
                    isPublished: isPublished,
                    isVerified: isVerified,
                  );

                  final provider = context.read<AdminProvider>();
                  Navigator.pop(ctx);

                  if (isEditing) {
                    await provider.updateReview(newReview);
                  } else {
                    await provider.addReview(newReview);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Review by "${newReview.authorName}" ${isPublished ? "published live to website" : "saved"}!'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ======================= DELETE CONFIRMATION =======================
  void _confirmDeleteReview(BuildContext context, ReviewModel review, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review?'),
        content: Text('Are you sure you want to permanently delete the review by "${review.authorName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteReview(review.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Review by "${review.authorName}" deleted.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
