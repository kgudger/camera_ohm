ColorLabel classifyKnn(
  double h,
  double s,
  double v,
  List<ColorSample> samples,
) 
  final sorted = [...samples];
{
  sorted.sort((a, b) {
    final da = hsvDistance(h, s, v, a.h, a.s, a.v);
    final db = hsvDistance(h, s, v, b.h, b.s, b.v);

    return da.compareTo(db);
  });

  // Use top 3 neighbors
  final top = samples.take(3);

  final votes = <ColorLabel, int>{};

  for (final sample in top) {
    votes[sample.label] =
        (votes[sample.label] ?? 0) + 1;
  }

  return votes.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
}

double hsvDistance(
  double h1,
  double s1,
  double v1,
  double h2,
  double s2,
  double v2,
) {
  final dh = hueDistance(h1, h2) / 180.0;
  final ds = s1 - s2;
  final dv = v1 - v2;

  return dh * dh * 4.0 +
      ds * ds * 2.0 +
      dv * dv;
}

double hueDistance(double h1, double h2) {
  final d = (h1 - h2).abs();
  return d > 180 ? 360 - d : d;
}

final samples = <ColorSample>[
  ColorSample(2, 0.82, 0.71, ColorLabel.red),
  ColorSample(7, 0.76, 0.66, ColorLabel.red),

  ColorSample(30, 0.45, 0.62, ColorLabel.gold),
  ColorSample(34, 0.52, 0.58, ColorLabel.gold),

  ColorSample(110, 0.75, 0.55, ColorLabel.green),

  ColorSample(0, 0.05, 0.90, ColorLabel.white),
];

class ColorSample {
  final double h;
  final double s;
  final double v;
  final ColorLabel label;

  ColorSample(this.h, this.s, this.v, this.label);
}