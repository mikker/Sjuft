import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var counterLabel: UILabel!
    
    var token: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.token = flux.listen { state in
            self.counterLabel.text = String(state.count)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        flux.dispatch(CounterActions.async(666))
    }
    
    deinit {
        flux.unlisten(token)
    }
    
    @IBAction func increment(sender: AnyObject?) {
        flux.dispatch(CounterActions.increment())
    }
    
    @IBAction func decrement(sender: AnyObject?) {
        flux.dispatch(CounterActions.decrement())
    }

}

