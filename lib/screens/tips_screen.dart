import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Tricks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTipCard(
            context,
            'Soil Health',
            'assets/images/soil_health.jpg',
            '''
### Key Points
- Test soil pH regularly
- Add organic matter
- Practice crop rotation
- Avoid soil compaction

### Best Practices
1. Compost regularly
2. Use cover crops
3. Mulch appropriately
4. Maintain proper drainage

### Benefits
- Better nutrient uptake
- Improved water retention
- Healthier plants
- Reduced disease risk
''',
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            'Watering Guide',
            'assets/images/watering.jpg',
            '''
### When to Water
- Early morning or evening
- When top soil is dry
- Before signs of wilting
- During growing season

### How to Water
1. Water deeply and less frequently
2. Target the root zone
3. Avoid wetting foliage
4. Use mulch to retain moisture

### Common Mistakes
- Overwatering
- Inconsistent watering
- Shallow watering
- Wrong timing
''',
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            'Natural Pest Control',
            'assets/images/pest_control.jpg',
            '''
### Prevention
- Companion planting
- Healthy soil
- Biodiversity
- Regular monitoring

### Natural Solutions
1. Beneficial insects
2. Neem oil
3. Companion plants
4. Physical barriers

### Common Helpers
- Ladybugs
- Praying mantis
- Birds
- Beneficial nematodes
''',
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            context,
            'Pruning Techniques',
            'assets/images/pruning.jpg',
            '''
### When to Prune
- During dormancy
- After flowering
- When damaged
- For shaping

### Basic Steps
1. Use clean, sharp tools
2. Cut at proper angles
3. Remove dead/diseased parts
4. Maintain plant shape

### Benefits
- Better air circulation
- Increased yield
- Disease prevention
- Improved appearance
''',
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    String title,
    String imagePath,
    String content,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imagePath,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    h3: Theme.of(context).textTheme.titleLarge,
                    p: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
