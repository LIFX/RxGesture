//
//  ViewController.swift
//  RxGesture
//
//  Created by Marin Todorov on 03/22/2016.
//  Copyright (c) 2016 Marin Todorov. All rights reserved.
//

import UIKit

import RxSwift
import RxGesture

class Step {
    enum Action { case previous, next }

    let title: String
    let code: String
    let install: (UIView, UILabel, AnyObserver<Action>, DisposeBag) -> Void

    init(title: String, code: String, install: @escaping (UIView, UILabel, AnyObserver<Action>, DisposeBag) -> Void) {
        self.title = title
        self.code = code
        self.install = install
    }
}

class ViewController: UIViewController {

    @IBOutlet var myView: UIView!
    @IBOutlet var myViewText: UILabel!
    @IBOutlet var info: UILabel!
    @IBOutlet var code: UITextView!

    private let nextStepObserver = PublishSubject<Step.Action>()
    private let bag = DisposeBag()
    private var stepBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        var steps: [Step] = [
            tapStep,
            doubleTapStep,
            swipeDownStep,
            swipeHorizontallyStep,
            longPressStep,
            touchDownStep,
            panStep,
            pinchStep,
            rotateStep,
            transformStep
        ]

        if #available(iOS 9.0, *), let index = steps.index(where: { $0 === panStep }) {
            steps.insert(forceTouchStep, at: index)
        }

        func newIndex(for index: Int, action: Step.Action) -> Int {
            switch action {
            case .previous:
                return index > 0 ? index - 1 : steps.count - 1
            case .next:
                return index < steps.count - 1 ? index + 1 : 0
            }
        }

        nextStepObserver
            .scan(0, accumulator: newIndex)
            .startWith(0)
            .map { (steps[$0], $0) }
            .subscribe(onNext: { [unowned self] in self.updateStep($0, at: $1) })
            .disposed(by: bag)
    }

    @IBAction func previousStep(_ sender: Any) {
        nextStepObserver.onNext(.previous)
    }

    @IBAction func nextStep(_ sender: Any) {
        nextStepObserver.onNext(.next)
    }

    func updateStep(_ step: Step, at index: Int) {
        stepBag = DisposeBag()

        info.text = "\(index + 1). " + step.title
        code.text = step.code

        myViewText.text = nil
        step.install(myView, myViewText, nextStepObserver.asObserver(), stepBag)

        print("active gestures: \(myView.gestureRecognizers?.count ?? 0)")
    }

    lazy var tapStep: Step = Step(
        title: "Tap the red square",
        code: """
        view.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .red)

            view.rx
                .tapGesture()
                .when(.recognized)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var doubleTapStep: Step = Step(
        title: "Double tap the green square",
        code: """
        view.rx
            .tapGesture() { gesture, _ in
                gesture.numberOfTapsRequired = 2
            }
            .when(.recognized)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .green)

            view.rx
                .tapGesture() { gesture, _ in
                    gesture.numberOfTapsRequired = 2
                }
                .when(.recognized)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var swipeDownStep: Step = Step(
        title: "Swipe the blue square down",
        code: """
        view.rx
            .swipeGesture(.down)
            .when(.recognized)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .blue)

            view.rx
                .swipeGesture(.down)
                .when(.recognized)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var swipeHorizontallyStep: Step = Step(
        title: "Swipe horizontally the blue square (e.g. left or right)",
        code: """
        view.rx
            .swipeGesture([.left, .right])
            .when(.recognized)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: CGAffineTransform(scaleX: 1.0, y: 2.0))
            view.animateBackgroundColor(to: .blue)

            view.rx
                .swipeGesture([.left, .right])
                .when(.recognized)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var longPressStep: Step = Step(
        title: "Do a long press",
        code: """
        view.rx
            .longPressGesture()
            .when(.began)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: CGAffineTransform(scaleX: 2.0, y: 2.0))
            view.animateBackgroundColor(to: .blue)

            view.rx
                .longPressGesture()
                .when(.began)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var touchDownStep: Step = Step(
        title: "Touch down the view",
        code: """
        view.rx
            .touchDownGesture()
            .when(.began)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, _, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .green)

            view.rx
                .touchDownGesture()
                .when(.began)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    @available(iOS 9.0, *)
    lazy var forceTouchStep: Step = Step(
        title: "Force Touch the view",
        code: """
        let forceTouch = view.rx.forceTouchGesture().share(replay: 1)

        forceTouch
            .asForce()
            .subscribe(onNext: { force in
                // Do something
            })
            .disposed(by: stepBag)

        forceTouch
            .when(.ended)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: stepBag)
        """,
        install: { view, label, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .red)

            let forceTouch = view.rx.forceTouchGesture().share(replay: 1)

            self.makeImpact(on: forceTouch, stepBag: stepBag)

            forceTouch
                .asForce()
                .subscribe(onNext: { force in
                    label.text = String(format: "%.2f", force)
                })
                .disposed(by: stepBag)

            forceTouch
                .when(.ended)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)

    })

    lazy var panStep: Step = Step(
        title: "Drag the square to a different location",
        code: """
        let panGesture = view.rx.panGesture().share(replay: 1)

        panGesture
            .when(.changed)
            .asTranslation()
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)

        panGesture
            .when(.ended)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, label, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .blue)

            let panGesture = view.rx.panGesture().share(replay: 1)

            panGesture
                .when(.changed)
                .asTranslation()
                .subscribe(onNext: { [unowned self] translation, _ in
                    label.text = String(format: "(%.2f, %.2f)", translation.x, translation.y)
                    view.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                })
                .disposed(by: stepBag)

            panGesture
                .when(.ended)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
               .disposed(by: stepBag)
    })

    lazy var rotateStep: Step = Step(
        title: "Rotate the square",
        code: """
        let rotationGesture = view.rx.rotationGesture().share(replay: 1)

        rotationGesture
            .when(.changed)
            .asRotation()
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)

        rotationGesture
            .when(.ended)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, label, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .blue)

            let rotationGesture = self.view.rx.rotationGesture().share(replay: 1)

            rotationGesture
                .when(.changed)
                .asRotation()
                .subscribe(onNext: { [unowned self] rotation, _ in
                    label.text = String(format: "%.2f rad", rotation)
                    view.transform = CGAffineTransform(rotationAngle: rotation)
                })
                .disposed(by: stepBag)

            rotationGesture
                .when(.ended)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var pinchStep: Step = Step(
        title: "Pinch the square",
        code: """
        let pinchGesture = view.rx.pinchGesture().share(replay: 1)

        pinchGesture
            .when(.changed)
            .asScale()
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)

        pinchGesture
            .when(.ended)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, label, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .blue)

            let pinchGesture = self.view.rx.pinchGesture().share(replay: 1)

            pinchGesture
                .when(.changed)
                .asScale()
                .subscribe(onNext: { scale, _ in
                    label.text = String(format: "x%.2f", scale)
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                })
                .disposed(by: stepBag)

            pinchGesture
                .when(.ended)
                .subscribe(onNext: { _ in
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    lazy var transformStep: Step = Step(
        title: "Transform the square",
        code: """
        let transformGestures = view.rx.transformGestures().share(replay: 1)

        transformGestures
            .when(.changed)
            .asTransform()
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)

        transformGestures
            .when(.ended)
            .subscribe(onNext: { _ in
                // Do something
            })
            .disposed(by: disposeBag)
        """,
        install: { view, label, nextStep, stepBag in

            view.animateTransform(to: .identity)
            view.animateBackgroundColor(to: .blue)

            let transformGestures = view.rx.transformGestures().share(replay: 1)

            transformGestures
                .when(.changed)
                .asTransform()
                .subscribe(onNext: { transform, _ in
                    label.numberOfLines = 3
                    label.text = String(format: "[%.2f, %.2f,\n%.2f, %.2f,\n%.2f, %.2f]", transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty)
                    view.transform = transform
                })
                .disposed(by: stepBag)

            transformGestures
                .when(.ended)
                .subscribe(onNext: { _ in
                    label.numberOfLines = 1
                    nextStep.onNext(.next)
                })
                .disposed(by: stepBag)
    })

    @available(iOS 9, *)
    private func makeImpact(on forceTouch: Observable<ForceTouchGestureRecognizer>, stepBag: DisposeBag) {
        // It looks like #available(iOS 10.0, *) is ignored in the lazy var declaration ¯\_(ツ)_/¯
        guard #available(iOS 10.0, *) else { return }
        forceTouch
            .map { ($0.force / $0.maximumPossibleForce) > 0.7 ? UIImpactFeedbackStyle.medium : .light }
            .distinctUntilChanged()
            .skip(1)
            .subscribe(onNext: { style in
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            })
            .disposed(by: stepBag)
    }
}

private extension UIView {

    func animateTransform(to transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.5) {
            self.transform = transform
        }
    }

    func animateBackgroundColor(to color: UIColor) {
        UIView.animate(withDuration: 0.5) {
            self.backgroundColor = color
        }
    }
}
