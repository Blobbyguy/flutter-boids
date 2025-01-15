import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const BoidsApp());
}

class BoidsApp extends StatelessWidget {
  const BoidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boids Simulation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BoidsSimulation(),
    );
  }
}

class BoidsSimulation extends StatefulWidget {
  const BoidsSimulation({super.key});

  @override
  _BoidsSimulationState createState() => _BoidsSimulationState();
}

class _BoidsSimulationState extends State<BoidsSimulation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Boid> _boids = [];
  double _numBoids = 100;
  double _separationMultiplier = 1.0;
  double _alignmentMultiplier = 1.0;
  double _cohesionMultiplier = 1.0;
  Size? _widgetSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_update)
      ..repeat();

    _initializeBoids();
  }

  void _initializeBoids() {
    _boids.clear();

    if (_widgetSize == null){
      return;
    }

    for (int i = 0; i < _numBoids; i++) {
      _boids.add(Boid(
        position: Offset(Random().nextDouble() * _widgetSize!.width, Random().nextDouble() * _widgetSize!.height),
        velocity: Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
      ));
    }
  }

  void _update() {
    if (_widgetSize == null) {
      return;
    }

    setState(() {
      for (var boid in _boids) {
        boid.update(_boids, _widgetSize!, _separationMultiplier, _alignmentMultiplier, _cohesionMultiplier);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boids Simulation'),
      ),
      body: Column(
        children: [
          _buildSliders(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
                return CustomPaint(
                  painter: BoidsPainter(_boids),
                  child: Container(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliders() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildSlider('Number of Boids', _numBoids, 10, 200, (value) {
          setState(() {
            _numBoids = value;
            _initializeBoids();
          });
        }, intOnly: true),
        _buildSlider('Separation', _separationMultiplier, 0, 1, (value) {
          setState(() {
            _separationMultiplier = value;
          });
        }),
        _buildSlider('Alignment', _alignmentMultiplier, 0, 1, (value) {
          setState(() {
            _alignmentMultiplier = value;
          });
        }),
        _buildSlider('Cohesion', _cohesionMultiplier, 0, 1, (value) {
          setState(() {
            _cohesionMultiplier = value;
          });
        }),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, {bool intOnly = false}) {
    return Row(
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: intOnly ? (max - min).toInt() : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
class Boid {
  Offset position;
  Offset velocity;

  Boid({required this.position, required this.velocity});

  void update(List<Boid> boids, Size screenSize, double separationMultiplier, double alignmentMultiplier, double cohesionMultiplier) {
    final separation = _separation(boids) * separationMultiplier;
    final alignment = _alignment(boids) * alignmentMultiplier;
    final cohesion = _cohesion(boids) * cohesionMultiplier;
    final boundaryAvoidance = _boundaryAvoidance(screenSize);

    velocity += separation + alignment + cohesion + boundaryAvoidance;
    velocity = Offset.fromDirection(velocity.direction, min(velocity.distance, 2.0));
    position += velocity;
  }

  Offset _separation(List<Boid> boids) {
    const double desiredSeparation = 25.0;
    Offset steer = Offset.zero;
    int count = 0;

    for (var other in boids) {
      final distance = (position - other.position).distance;
      if (distance > 0 && distance < desiredSeparation) {
        steer += (position - other.position) / distance;
        count++;
      }
    }

    if (count > 0) {
      steer /= count.toDouble();
    }

    return steer;
  }

  Offset _alignment(List<Boid> boids) {
    const double neighborDist = 50.0;
    Offset sum = Offset.zero;
    int count = 0;

    for (var other in boids) {
      final distance = (position - other.position).distance;
      if (distance > 0 && distance < neighborDist) {
        sum += other.velocity;
        count++;
      }
    }

    if (count > 0) {
      sum /= count.toDouble();
      sum = Offset.fromDirection(sum.direction, min(sum.distance, 2.0));
      return (sum - velocity) / 8.0;
    }

    return Offset.zero;
  }

  Offset _cohesion(List<Boid> boids) {
    const double neighborDist = 50.0;
    Offset sum = Offset.zero;
    int count = 0;

    for (var other in boids) {
      final distance = (position - other.position).distance;
      if (distance > 0 && distance < neighborDist) {
        sum += other.position;
        count++;
      }
    }

    if (count > 0) {
      sum /= count.toDouble();
      return (sum - position) / 100.0;
    }

    return Offset.zero;
  }

  Offset _boundaryAvoidance(Size screenSize) {
    const double margin = 15.0;
    const double turnFactor = 1.0;
    Offset steer = Offset.zero;

    if (position.dx < margin) {
      steer += Offset(turnFactor, 0);
    } else if (position.dx > screenSize.width - margin) {
      steer += Offset(-turnFactor, 0);
    }

    if (position.dy < margin) {
      steer += Offset(0, turnFactor);
    } else if (position.dy > screenSize.height - margin) {
      steer += Offset(0, -turnFactor);
    }

    return steer;
  }
}

class BoidsPainter extends CustomPainter {
  final List<Boid> boids;

  BoidsPainter(this.boids);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (var boid in boids) {
      canvas.drawCircle(boid.position, 3.0, paint);
    }

    // Draw boundary box
    final boundaryPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      boundaryPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}