library rounded_loading_button;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LoadingState { idle, loading, success, error }

class RoundedLoadingButton extends StatefulWidget {
  final RoundedLoadingButtonController controller;

  /// The callback that is called when the button is tapped or otherwise activated.
  final VoidCallback onPressed;

  /// The button's label
  final Widget child;

  /// The primary color of the button
  final Color color;

  /// The vertical extent of the button.
  final double height;

  /// The horiztonal extent of the button.
  final double width;

  /// Whether to trigger the animation on the tap event
  final bool animateOnTap;

  /// The color of the static icons
  final Color valueColor;

  /// The curve of the shrink animation
  final Curve curve;

  /// The radius of the button border
  final double borderRadius;

  /// The duration of the button animation
  final Duration duration;

  /// The elevation of the raised button
  final double elevation;

  final Color borderColor;

  final double borderWidth;

  final Color errorStateColor;

  final Duration afterAnimationTimeout;

  Duration get _borderDuration {
    return new Duration(milliseconds: (this.duration.inMilliseconds / 2).round());
  }

  RoundedLoadingButton(
      {Key key,
        this.controller,
        this.onPressed,
        this.child,
        this.color,
        this.height = 50,
        this.width = 300,
        this.animateOnTap = true,
        this.valueColor = Colors.white,
        this.borderRadius = 35,
        this.elevation = 0.0,
        this.duration = const Duration(milliseconds: 500),
        this.curve = Curves.easeInOutCirc,
        this.borderColor = Colors.transparent,
        this.borderWidth = 0.0,
        this.errorStateColor = Colors.red,
        this.afterAnimationTimeout = const Duration(seconds: 1)});

  @override
  State<StatefulWidget> createState() => RoundedLoadingButtonState();
}

class RoundedLoadingButtonState extends State<RoundedLoadingButton> with TickerProviderStateMixin {
  AnimationController _buttonController;
  AnimationController _borderController;
  AnimationController _checkButtonController;

  Animation _squeezeAnimation;
  Animation _bounceAnimation;
  Animation _borderAnimation;

  CurrentLoadingButtonState _stateChangeNotifier;

  @override
  void initState() {
    super.initState();

    _stateChangeNotifier = CurrentLoadingButtonState(LoadingState.idle);
    _buttonController = new AnimationController(duration: widget.duration, vsync: this);

    _checkButtonController = new AnimationController(duration: new Duration(milliseconds: 1000), vsync: this);

    _borderController = new AnimationController(duration: widget._borderDuration, vsync: this);

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height).animate(new CurvedAnimation(parent: _checkButtonController, curve: Curves.elasticOut));
    _bounceAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation = Tween<double>(begin: widget.width, end: widget.height).animate(new CurvedAnimation(parent: _buttonController, curve: widget.curve));

    _squeezeAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation.addStatusListener((state) {
      if (state == AnimationStatus.completed && widget.animateOnTap) {
        widget.onPressed();
      }
    });

    _borderAnimation = BorderRadiusTween(begin: BorderRadius.circular(widget.borderRadius), end: BorderRadius.circular(widget.height)).animate(_borderController);

    _borderAnimation.addListener(() {
      setState(() {});
    });

    widget.controller?._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var _check = Container(
        alignment: FractionalOffset.center,
        decoration: new BoxDecoration(
          color: widget.color ?? theme.primaryColor,
          borderRadius: new BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
        ),
        width: _bounceAnimation.value,
        height: _bounceAnimation.value,
        child: _bounceAnimation.value > 20
            ? Icon(
          Icons.check,
          color: widget.valueColor,
        )
            : null);
    var _cross = Container(
        alignment: FractionalOffset.center,
        decoration: new BoxDecoration(
            color: widget.errorStateColor,
            borderRadius: new BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
            border: Border.fromBorderSide(BorderSide(color: widget.borderColor, width: widget.borderWidth))),
        width: _bounceAnimation.value,
        height: _bounceAnimation.value,
        child: _bounceAnimation.value > 20
            ? Icon(
          Icons.close,
          color: widget.valueColor,
        )
            : null);

    var _loader = SizedBox(
        height: widget.height - 25, width: widget.height - 25, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor), strokeWidth: 2));

    var childStream = Consumer<CurrentLoadingButtonState>(
      builder: (BuildContext context, CurrentLoadingButtonState state, _) {
        return AnimatedSwitcher(duration: Duration(milliseconds: 200), child: state.state == LoadingState.loading ? _loader : widget.child);
      },
    );

    var _btn = ButtonTheme(
        shape: RoundedRectangleBorder(side: BorderSide(color: widget.borderColor, width: widget.borderWidth), borderRadius: _borderAnimation.value),
        minWidth: _squeezeAnimation.value,
        height: widget.height,
        child: RaisedButton(
            padding: EdgeInsets.all(0), child: childStream, color: widget.color ?? theme.primaryColor, elevation: widget.elevation, onPressed: widget.onPressed == null ? null : _btnPressed));

    return ChangeNotifierProvider.value(
      value: _stateChangeNotifier,
      child: Container(
          height: widget.height,
          child: Center(
              child: _stateChangeNotifier.state == LoadingState.error
                  ? _cross
                  : _stateChangeNotifier.state == LoadingState.success
                  ? _check
                  : _btn)),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _checkButtonController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  _btnPressed() async {
    if (widget.animateOnTap) {
      _start();
    } else {
      if (_stateChangeNotifier.state == LoadingState.idle) widget.onPressed();
    }
  }

  _start() {
    _stateChangeNotifier.state = LoadingState.loading;
    _borderController.forward();
    _buttonController.forward();
  }

  _stop() {
    _stateChangeNotifier.state = LoadingState.idle;
    _buttonController.reverse();
    _borderController.reverse();
  }

  _success(VoidCallback onAfterAnimation) async {
    await Future.sync(() => _stateChangeNotifier.state = LoadingState.success)
        .then((_) => _checkButtonController.forward())
        .then((value) => Future.delayed(widget.afterAnimationTimeout, onAfterAnimation));
  }

  _error(VoidCallback onAfterAnimation) async {
    await Future.sync(() => _stateChangeNotifier.state = LoadingState.error)
        .then((_) => _checkButtonController.forward())
        .then((value) => Future.delayed(widget.afterAnimationTimeout, onAfterAnimation));
  }

  _reset() async {
    await Future.wait([_borderController.reverse(), _checkButtonController.reverse()])
        .then((value) => _stateChangeNotifier.state = LoadingState.idle)
        .then((value) => _buttonController.reverse());
  }
}

class RoundedLoadingButtonController {
  VoidCallback _startListener;
  VoidCallback _stopListener;
  Function(VoidCallback) _successListener;
  Function(VoidCallback) _errorListener;
  VoidCallback _resetListener;

  _addListeners(VoidCallback startListener, VoidCallback stopListener, Function(VoidCallback) successListener, Function(VoidCallback) errorListener, VoidCallback resetListener) {
    this._startListener = startListener;
    this._stopListener = stopListener;
    this._successListener = successListener;
    this._errorListener = errorListener;
    this._resetListener = resetListener;
  }

  start() {
    _startListener();
  }

  stop() {
    _stopListener();
  }

  success({VoidCallback onAfterAnimation}) {
    _successListener(onAfterAnimation);
  }

  error({VoidCallback onAfterAnimation}) {
    _errorListener(onAfterAnimation);
  }

  reset() {
    _resetListener();
  }
}

class CurrentLoadingButtonState extends ChangeNotifier {
  LoadingState _state;

  LoadingState get state => _state;

  set state(LoadingState state) {
    _state = state;
    notifyListeners();
  }

  CurrentLoadingButtonState(LoadingState state) : assert(state != null) {
    this.state = state;
  }
}
