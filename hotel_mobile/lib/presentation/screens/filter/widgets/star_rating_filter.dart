import 'package:flutter/material.dart';

class StarRatingFilter extends StatelessWidget {
  final List<int> selectedRatings;
  final Function(List<int>) onChanged;

  const StarRatingFilter({
    Key? key,
    required this.selectedRatings,
    required this.onChanged,
  }) : super(key: key);

  void _toggleRating(int rating) {
    List<int> newRatings = List.from(selectedRatings);
    if (newRatings.contains(rating)) {
      newRatings.remove(rating);
    } else {
      newRatings.add(rating);
    }
    newRatings.sort();
    onChanged(newRatings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Xếp hạng sao',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Star Rating Options
          Column(
            children: List.generate(5, (index) {
              final rating = 5 - index; // 5 sao -> 1 sao
              final isSelected = selectedRatings.contains(rating);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _toggleRating(rating),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[600]!
                            : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[600]!
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),

                        const SizedBox(width: 12),

                        // Stars
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: starIndex < rating
                                  ? Colors.amber[600]
                                  : Colors.grey[300],
                              size: 18,
                            );
                          }),
                        ),

                        const SizedBox(width: 8),

                        // Rating Text
                        Text(
                          rating == 5 ? '5 sao' : 'Từ $rating sao trở lên',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.black87,
                          ),
                        ),

                        const Spacer(),

                        // Count (mock data)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_getMockCount(rating)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          // Selected Summary
          if (selectedRatings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã chọn ${selectedRatings.length} mức xếp hạng',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onChanged([]),
                    child: Text(
                      'Xóa tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getMockCount(int rating) {
    // Mock data - trong thực tế sẽ lấy từ API
    switch (rating) {
      case 5:
        return 25;
      case 4:
        return 45;
      case 3:
        return 38;
      case 2:
        return 22;
      case 1:
        return 15;
      default:
        return 0;
    }
  }
}
