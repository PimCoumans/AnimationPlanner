# ``AnimationPlanner``

Chain multiple `UIView` animations with a declarative syntax, describing each step along the way.

## Overview

Start your animation with ``AnimationPlanner/AnimationPlanner/plan(animations:completion:)`` to begin your animation sequence. From within the `animations` closure you can add your animations.
The most often used animation types are listed below.

| Animation   | Description                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------- |
| ``Animate`` | Perform an aninimation with duration in seconds.                                                    |
| ``Wait``    | Pauses the sequence for a given amount of seconds.                                                  |
| ``Extra``   | prepare state before or between your steps or perform side-effects like triggering haptic feedback  |

## Topics

### Examples

- <doc:typical-implementation>

### Animation creation

- ``AnimationPlanner/AnimationPlanner/plan(animations:completion:)``
- ``AnimationPlanner/AnimationPlanner/group(animations:completion:)``

### Animation modifiers methods

To change the way the animation is performed, a spring animation or a delay can be added through the a spring and delay modifiers.

Spring and delay animations can also be created as seperate structs by using the initializers of ``AnimateSpring`` or ``AnimateDelayed``.

- ``SpringModifier/spring(damping:initialVelocity:)-33bwh``
- ``DelayModifier/delayed(_:)-7lnka``

### Property modifier methods

All animations conforming to ``AnimationModifiers`` can use modifier methods that add or update specific properties.

To add both ``Animation/options`` and a ``Animation/timingFunction`` to your animation, call each method subsequently. 
```swift
Animate(duration: 0.5) { view.transform = .identity }
    .options(.allowUserInteraction)
    .timingFunction(.quintOut)
```

- ``AnimationModifiers/options(_:)``
- ``AnimationModifiers/timingFunction(_:)``
- ``AnimationModifiers/changes(_:)``

### Grouped animation

To perform multiple animations simultaneously, a `Group` can be created in which animations can be contained.
- ``Group``
- ``Sequence``
