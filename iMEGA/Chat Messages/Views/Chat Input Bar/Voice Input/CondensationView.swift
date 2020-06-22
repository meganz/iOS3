
class CondensationView: EnlargementView {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var originalBottomValue: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        enlarge = false
        originalBottomValue = bottomConstraint.constant
    }
    
    override func updateUI() {
        super.updateUI()
        
        bottomConstraint.constant = originalBottomValue + singleSideAddedWidth
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        selectionView.backgroundColor = .mnz_inputbarButtonBackground(traitCollection)
        nonSelectionView.backgroundColor = .mnz_redFF453A()
    }
}