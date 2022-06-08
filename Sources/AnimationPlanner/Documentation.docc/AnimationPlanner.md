# ``AnimationPlanner``

Chain multiple `UIView` animations with a declarative syntax, describing each step along the way.

## Overview

Use the extension method ``StepAnimatable/animateSteps(_:completion:)-8lxza`` (made available through `UIView.animateSteps(_:completion:)`) to begin your animation sequence. Use the provided ``AnimationSequence`` object to add each step. Possible steps are:
- Delay ``AnimationSequence/delay(_:)``: add a delay step that pauses the sequence for the given amount of seconds
- Animation ``AnimationSequence/add(duration:options:timingFunction:animations:)``: add an animation step with a desired duration and optionally animation options and a timing function
- Spring animation ``AnimationSequence/addSpring(duration:delay:damping:initialVelocity:options:animations:)``: add a spring-based animation step with the expected damping and velocity values. Timing curves aren‘t available in this method by design, the spring itself should do all the interpolating.
- Extra ``AnimationSequence/extra(_:)``: prepare state before or between steps for the next animation or perform side-effects like triggering haptic feedback.
- Group ``AnimationSequence/addGroup(with:)``: add an animation group (See ``AnimationSequence/Group``) where each animation added to this group animates at the same time

## Topics

### Examples

- <doc:typical-implementation>

### Animation creation

- ``AnimationSequence``
- ``AnimationSequence/Group``
- ``StepAnimatable``
