# ``AnimationPlanner``

Chain multiple `UIView` animations with a declarative syntax, describing each step along the way.

## Overview

Use the extension method ``StepAnimatable/animateSteps(_:completion:)-8lxza`` (made available through `UIView.animateSteps(_:completion:)`) to begin your animation sequence. Use the provided ``AnimationSequence`` object to add each steps. Posible steps are:
- Delay ``AnimationSequence/delay(_:)``: add a delay step which pauses the sequences for the given amount of seconds
- Animation ``AnimationSequence/add(duration:options:timingFunction:animations:)``: add an animation step with a duration and optionally animation options and a timing function
- Spring animation ``AnimationSequence/addSpring(duration:delay:damping:initialVelocity:options:animations:)``: add a spring-based animation step with the expected damping and velocity values. Timing curves aren‘t available in this method by design, the spring itself should do all the interpolating.
- Group ``AnimationSequence/addGroup(with:)``: add an animation group (See ``AnimationSequence/Group``) where each animation added to this group animates at the same time

## Topics

### Examples

- <doc:typical-implementation>

### Animation creation

- ``AnimationSequence``
- ``AnimationSequence/Group``
- ``StepAnimatable``
