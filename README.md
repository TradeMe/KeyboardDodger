## KeyboardDodger

KeyboardDodger is an iOS cocoapod that uses a constraint to move a view out of the way of the on-screen keyboard.

### Installation

```ruby
pod 'KeyboardDodger', '~> 1.0'
```

### Usage

KeyboardDodger attaches to a view and a constraint at the bottom of the view, and manipulates the constraint to keep it out of the way of the on-screen keyboard.

An example implementation:

```swift
class ViewController: UIViewController {

    var bottomConstraint: NSLayoutConstraint?

    var keyboardDodger: KeyboardDodger?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let bottomConstraint = bottomConstraint {
            keyboardDodger = KeyboardDodger(view: view, constraint: bottomConstraint, delegate: self)
        }
    }

}

extension ViewController: KeyboardDodgerDelegate {
    
    func keyboardDodger(_ keyboardDodger: KeyboardDodger, willUpdateConstraintWith transition: KeyboardDodgerTransition) {
        print("Keyboard dodger will update constraint")
    }
    
    func keyboardDodger(_ keyboardDodger: KeyboardDodger, didUpdateConstraintWith transition: KeyboardDodgerTransition) {
        print("Keyboard dodger did update constraint")
    }

}
```
