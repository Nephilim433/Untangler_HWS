
import UIKit

class ViewController: UIViewController {

    var currentLevel = 0
    var conntections = [ConntectionView]()
    let renderedLines = UIImageView()

    let scoreLabel = UILabel()

    var score = 0 {
        didSet{
            scoreLabel.text = String("Score :\(score)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        score = 0
        scoreLabel.textColor = .cyan
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 24)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)


        renderedLines.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderedLines)
        NSLayoutConstraint.activate([
            renderedLines.topAnchor.constraint(equalTo: view.topAnchor),
            renderedLines.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            renderedLines.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderedLines.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            scoreLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.backgroundColor = .darkGray
        levelUp()
        // Do any additional setup after loading the view.
    }

    private func levelUp() {
        currentLevel += 1

        conntections.forEach { $0.removeFromSuperview() }
        conntections.removeAll()

        for _ in 1...(currentLevel + 4) {
            let conntection = ConntectionView(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
            conntection.backgroundColor = .white
            conntection.layer.cornerRadius = 22
            conntection.layer.borderWidth = 2
            conntection.clipsToBounds = true
            conntections.append(conntection)
            view.addSubview(conntection)

            conntection.dragChanged = { [weak self] in
                self?.redrawLines()
            }
            conntection.dragFinished = { [weak self] in
                self?.checkMove()
            }
        }

        for i in 0..<conntections.count {
            if i == conntections.count - 1 {
                conntections[i].after = conntections[0]
            } else {
                conntections[i].after = conntections[i + 1]
            }
        }
        //wow, this is neat!

        repeat {
            conntections.forEach(place)
        } while leverClear()

        redrawLines()

    }
    func place(_ connection: ConntectionView) {
        let randomX = CGFloat.random(in: 20...view.bounds.maxX - 20)
        let randomY = CGFloat.random(in: 50...view.bounds.maxY - 50)
        connection.center = CGPoint(x: randomX, y: randomY)
    }

    func redrawLines() {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        renderedLines.image = renderer.image(actions: { ctx in
            for conntection in conntections {
                var isLineClear = true

                for other in conntections {
                    if linesCross(start1: conntection.center, end1: conntection.after.center, start2: other.center, end2: other.after.center) != nil {
                        isLineClear = false
                        break
                    }
                }

                if isLineClear  {
                    UIColor.green.set()
                } else {
                    UIColor.red.set()
                }
                ctx.cgContext.strokeLineSegments(between: [conntection.after.center,conntection.center])
            }
        })
    }
    func linesCross(start1: CGPoint, end1: CGPoint, start2: CGPoint, end2: CGPoint) -> (x: CGFloat, y: CGFloat)? {
        // calculate the differences between the start and end X/Y positions for each of our points
        let delta1x = end1.x - start1.x
        let delta1y = end1.y - start1.y
        let delta2x = end2.x - start2.x
        let delta2y = end2.y - start2.y

        // create a 2D matrix from our vectors and calculate the determinant
        let determinant = delta1x * delta2y - delta2x * delta1y

        if abs(determinant) < 0.0001 {
            // if the determinant is effectively zero then the lines are parallel/colinear
            return nil
        }

        // if the coefficients both lie between 0 and 1 then we have an intersection
        let ab = ((start1.y - start2.y) * delta2x - (start1.x - start2.x) * delta2y) / determinant

        if ab > 0 && ab < 1 {
            let cd = ((start1.y - start2.y) * delta1x - (start1.x - start2.x) * delta1y) / determinant

            if cd > 0 && cd < 1 {
                // lines cross – figure out exactly where and return it
                let intersectX = start1.x + ab * delta1x
                let intersectY = start1.y + ab * delta1y
                return (intersectX, intersectY)
            }
        }

        // lines don't cross
        return nil
    }

    func leverClear() -> Bool {
        for conntection in conntections {
            for other in conntections {
                if linesCross(start1: conntection.center, end1: conntection.after.center, start2: other.center, end2: other.after.center) != nil {
                    return false
                }
            }
        }
        return true
    }

    func checkMove() {
        if leverClear() {
            //win
            score += currentLevel * 2
            view.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5, delay: 1, options: []) {
                self.renderedLines.alpha = 0

                for conntection in self.conntections {
                    conntection.alpha = 0
                }
            } completion: { finished in
                self.view.isUserInteractionEnabled = true
                self.renderedLines.alpha = 1
                self.levelUp()
            }

        } else {
            score -= 1
        }
    }
}

