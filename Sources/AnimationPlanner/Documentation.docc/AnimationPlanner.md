# ``AnimationPlanner``

Chain multiple `UIView` animations with a clear declarative syntax, describing each step along the way. AnimationPlanner allows you to easily create all your animations in the same indentation level using a convenient API leveraging Swift result builders.

## Overview

Start by typing `AnimationPlanner.plan` and begin creating your animation sequence. Within the `animations` closure you can provide all of your animations. Using the returned ``RunningSequence`` a completion handler can be added. 

> Note: Any animation created with AnimationPlanner can use a `CAMediaTimingFunction` animation curve with its animations. This framework provides numerous presets (like `.quintOut`) through an custom extension.

### Example

```swift
AnimationPlanner.plan {
    Animate(duration: 0.32) {
        view.transform = CGAffineTransform(scaleX: 2, y: 2)
        view.layer.cornerRadius = 40
        view.backgroundColor = .systemRed
    }.timingFunction(.quintOut)
    Wait(0.2)
    AnimateSpring(duration: 0.25, damping: 0.52) {
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 0
        view.transform = .identity
    }
}
```

See ``AnimationPlanner/AnimationPlanner/plan(animations:)`` on ``AnimationPlanner`` for more info on beginning your animation sequence.

The most often used animation types are listed below.

| Animation   | Description                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------- |
| ``Animate`` | Perform an aninimation with duration in seconds.                                                    |
| ``Wait``    | Pauses the sequence for a given amount of seconds.                                                  |
| ``Extra``   | prepare state before or between your steps or perform side-effects like triggering haptic feedback  |

## Topics

### Examples

- <doc:creating-basic-animation-sequence>

### Starting your animations

- ``AnimationPlanner/AnimationPlanner/plan(animations:)``
- ``AnimationPlanner/AnimationPlanner/group(animations:)``

### Animation structs

- ``Animate``
- ``Wait``
- ``AnimateSpring``
- ``AnimateDelayed``
- ``Extra``

### Animation modifiers methods

To change the way an animation is performed, the spring and delay modifiers can add specific behavior to your ``Animate`` struct.

Spring and delay animations can also be created as seperate structs by using the initializers of ``AnimateSpring`` or ``AnimateDelayed``
as described above.

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

### Loop

Iterating over a sequence of repeating animations for a specific amount of time can be done using `for element in sequence {` but also through
the ``Loop`` struct.

- ``Loop``

### Running sequence

Calling the main `AnimationPlanner` methods ``AnimationPlanner/AnimationPlanner/plan(animations:)`` and ``AnimationPlanner/AnimationPlanner/group(animations:)`` retuns in a ``RunningSequence`` object. This class allows you to add a completion handler with ``RunningSequence/onComplete(_:)`` and even stop the animations with ``RunningSequence/stopAnimations()``.

- ``RunningSequence``
