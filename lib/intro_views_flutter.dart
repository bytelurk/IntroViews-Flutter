library intro_views_flutter;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intro_views_flutter/Animation_Gesture/animated_page_dragger.dart';
import 'package:intro_views_flutter/Animation_Gesture/page_dragger.dart';
import 'package:intro_views_flutter/Animation_Gesture/page_reveal.dart';
import 'package:intro_views_flutter/Constants/constants.dart';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/Models/pager_indicator_view_model.dart';
import 'package:intro_views_flutter/Models/slide_update_model.dart';
import 'package:intro_views_flutter/UI/page_indicator_buttons.dart';
import 'package:intro_views_flutter/UI/pager_indicator.dart';
import 'package:intro_views_flutter/UI/page.dart';

/// This is the IntroViewsFlutter widget of app which is a stateful widget as its state is dynamic and updates asynchronously.
class IntroViewsFlutter extends StatefulWidget {
  /// List of [PageViewModel] to display
  final List<PageViewModel> pages;

  /// Callback on Done Button Pressed
  final VoidCallback onTapDoneButton;

  /// set the Text Color for skip, done buttons
  ///
  /// gets overiden by [pageButtonTextStyles]
  final Color pageButtonsColor;

  /// Whether you want to show the skip button or not.
  final bool showSkipButton;

  /// Whether you want to show the next button or not.
  final bool showNextButton;

  /// Whether you want to show the back button or not.
  final bool showBackButton;

  /// TextStyles for done, skip Buttons
  ///
  /// overrides [pageButtonFontFamily] [pageButtonsColor] [pageButtonTextSize]
  final TextStyle pageButtonTextStyles;

  /// run a function after skip Button pressed
  final VoidCallback onTapSkipButton;

  /// run a function after next Button pressed
  final VoidCallback onTapNextButton;

  /// run a function after back Button pressed
  final VoidCallback onTapBackButton;

  /// set the Text Size for skip, done buttons
  ///
  /// gets overridden by [pageButtonTextStyles]
  final double pageButtonTextSize;

  /// set the Font Family for skip, done buttons
  ///
  /// gets overridden by [pageButtonTextStyles]
  final String pageButtonFontFamily;

  /// Override 'DONE' Text with Your Own Text,
  /// typicaly a Text Widget
  final Widget doneText;

  /// Override 'BACK' Text with Your Own Text,
  /// typicaly a Text Widget
  final Widget backText;

  /// Override 'NEXT' Text with Your Own Text,
  /// typicaly a Text Widget
  final Widget nextText;

  /// Override 'Skip' Text with Your Own Text,
  /// typicaly a Text Widget
  final Widget skipText;

  /// always Show DoneButton
  final bool doneButtonPersist;

  /// [MainAxisAlignment] for [PageViewModel] page column aligment
  /// default [MainAxisAligment.spaceAround]
  ///
  /// portrait view wraps around  [title] [body] [mainImage]
  ///
  /// landscape view wraps around [title] [body]
  final MainAxisAlignment columnMainAxisAlignment;

  /// ajust how how much the user most drag for a full page transition
  ///
  /// default to 300.0
  final double fullTransition;

  final Color background;

  final RevealPosition revealPosition;

  final bool loop;

  IntroViewsFlutter(this.pages,
      {Key key,
      this.onTapDoneButton,
      this.showSkipButton = true,
      this.pageButtonTextStyles,
      this.onTapBackButton,
      this.showNextButton = false,
      this.showBackButton = false,
      this.pageButtonTextSize = 18.0,
      this.pageButtonFontFamily,
      this.onTapSkipButton,
      this.onTapNextButton,
      this.pageButtonsColor,
      this.doneText = const Text("DONE"),
      this.nextText = const Text("NEXT"),
      this.skipText = const Text("SKIP"),
      this.backText = const Text("BACK"),
      this.doneButtonPersist = false,
      this.columnMainAxisAlignment = MainAxisAlignment.spaceAround,
      this.fullTransition = FULL_TARNSITION_PX,
      this.background,
      this.revealPosition = RevealPosition.bottom,
      this.loop = false,
      })
      : super(key: key);

  @override
  _IntroViewsFlutterState createState() => _IntroViewsFlutterState();
}

/// State of above widget.
/// It extends the TickerProviderStateMixin as it is used for animation control (vsync).

class _IntroViewsFlutterState extends State<IntroViewsFlutter>
    with TickerProviderStateMixin {
  StreamController<SlideUpdate>
      // ignore: close_sinks
      slideUpdateStream; //Stream controller is used to get all the updates when user slides across screen.

  AnimatedPageDragger
      animatedPageDragger; //When user stops dragging then by using this page automatically drags.

  int activePageIndex = 0; //active page index
  int nextPageIndex = 0; //next page index
  SlideDirection slideDirection = SlideDirection.none; //slide direction
  double slidePercent = 0.0; //slide percentage (0.0 to 1.0)
  StreamSubscription<SlideUpdate> slideUpdateStream$;

  @override
  void initState() {
    //Stream Controller initialization
    slideUpdateStream = StreamController<SlideUpdate>();
    //listening to updates of stream controller
    slideUpdateStream$ = slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        //setState is used to change the values dynamically

        print("event.slidePercent=>"+event.slidePercent.toString());
        //if the user is dragging then
        if (event.updateType == UpdateType.dragging) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;

          //conditions on slide direction
          if (slideDirection == SlideDirection.leftToRight) {
//            nextPageIndex = max(0, activePageIndex - 1);
            nextPageIndex = activePageIndex - 1;
            if(nextPageIndex < 0){
              nextPageIndex = widget.pages.length - 1;
            }
          } else if (slideDirection == SlideDirection.rightToLeft) {
//            nextPageIndex = min(widget.pages.length - 1, activePageIndex + 1);
            nextPageIndex = activePageIndex + 1;
            if(nextPageIndex > (widget.pages.length - 1)){
              nextPageIndex = 0;
            }
          } else {
            nextPageIndex = activePageIndex;
          }
        }
        //if the user has done dragging
        else if (event.updateType == UpdateType.doneDragging) {
          //Auto completion of event using Animated page dragger.
          if (slidePercent > 0.5) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.open,
              //we have to animate the open page reveal
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.close,
              //we have to close the page reveal
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            //also next page is active page
            nextPageIndex = activePageIndex;
          }
          //Run the animation
          animatedPageDragger.run();
        }
        //when animating
        else if (event.updateType == UpdateType.animating) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;
        }
        //done animating
        else if (event.updateType == UpdateType.doneAnimating) {
          activePageIndex = nextPageIndex;

          slideDirection = SlideDirection.none;
          slidePercent = 0.0;

          //disposing the animation controller
          // animatedPageDragger?.dispose();
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    slideUpdateStream$?.cancel();
    animatedPageDragger?.dispose();
    slideUpdateStream?.close();
    super.dispose();
  }

  /// Build method

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
            fontSize: widget.pageButtonTextSize ?? 18.0,
            color: widget.pageButtonsColor ?? const Color(0x88FFFFFF),
            fontFamily: widget.pageButtonFontFamily)
        .merge(widget.pageButtonTextStyles);

    List<PageViewModel> pages = widget.pages;

    return Scaffold(
      //Stack is used to place components over one another.
      resizeToAvoidBottomPadding: false,
      backgroundColor: widget.background,
      body: Stack(
        children: <Widget>[
          Page(
            pageViewModel: pages[activePageIndex],
            percentVisible: 1.0,
            columnMainAxisAlignment: widget.columnMainAxisAlignment,
          ), //Pages
          PageReveal(
            //next page reveal
            revealPercent: slidePercent,
            slideDirection: slideDirection,
            revealPosition: widget.revealPosition,
            child: Page(
                pageViewModel: pages[nextPageIndex],
                percentVisible: slidePercent,
                columnMainAxisAlignment: widget.columnMainAxisAlignment),
          ), //PageReveal

          PagerIndicator(
            //bottom page indicator
            viewModel: PagerIndicatorViewModel(
              pages,
              activePageIndex,
              slideDirection,
              slidePercent,
            ),
          ), //PagerIndicator

          PageDragger(
            //Used for gesture control
            fullTransitionPX: widget.fullTransition,
            canDragLeftToRight: widget.loop == true ? widget.loop : activePageIndex > 0,
            canDragRightToLeft: widget.loop == true ? widget.loop: activePageIndex < pages.length - 1,
            slideUpdateStream: this.slideUpdateStream,
          ), //PageDragger
        ], //Widget
      ), //Stack
    ); //Scaffold
  }
}
