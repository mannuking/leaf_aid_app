import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DiseaseGuideScreen extends StatelessWidget {
  const DiseaseGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDiseaseCard(
            context,
            'Powdery Mildew',
            'assets/images/powdery_mildew.jpg',
            '''
### Symptoms
- White powdery spots on leaves and stems
- Yellowing and distortion of leaves
- Stunted growth
- Premature leaf drop

### Causes
- High humidity
- Poor air circulation
- Overcrowded plants
- Warm temperatures

### Treatment
1. Remove and destroy infected plant parts
2. Improve air circulation
3. Apply fungicides if necessary
4. Water at the base of plants
''',
          ),
          const SizedBox(height: 16),
          _buildDiseaseCard(
            context,
            'Leaf Spot',
            'assets/images/leaf_spot.jpg',
            '''
### Symptoms
- Brown or black spots on leaves
- Yellow halos around spots
- Spots may merge into larger areas
- Leaf drop

### Causes
- Fungal infection
- Wet conditions
- Poor air circulation
- Splashing water

### Treatment
1. Remove infected leaves
2. Avoid overhead watering
3. Improve spacing between plants
4. Use fungicides as needed
''',
          ),
          const SizedBox(height: 16),
          _buildDiseaseCard(
            context,
            'Root Rot',
            'assets/images/root_rot.jpg',
            '''
### Symptoms
- Wilting despite moist soil
- Yellowing leaves
- Stunted growth
- Brown, mushy roots

### Causes
- Overwatering
- Poor drainage
- Soil-borne pathogens
- Compacted soil

### Treatment
1. Improve drainage
2. Reduce watering frequency
3. Repot with fresh soil
4. Remove affected roots
''',
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(
    BuildContext context,
    String title,
    String imagePath,
    String description,
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
                  data: description,
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
