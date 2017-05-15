//
//  PDFPathAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/24/16.
//
//

import UIKit

class PDFPathAnnotation: NSObject, NSCoding {
    
    var page: Int?
    var uuid: String = UUID().uuidString
    var saved: Bool = false
    
    var path: UIBezierPath = UIBezierPath()
    var color: UIColor = UIColor.black {
        didSet {
            color.setStroke()
            path.stroke()
        }
    }
    var fill: Bool = false
    var lineWidth: CGFloat = 3.0 {
        didSet {
            path.lineWidth = lineWidth
        }
    }
    var rect: CGRect = CGRect(x: 0, y: 0, width: 1000, height: 1000) {
        didSet {
            view.frame = rect
        }
    }
    lazy var view: PDFPathView = PDFPathView(parent: self, frame: self.rect)
    var incrementalImage: UIImage?
    
    fileprivate var points: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    fileprivate var ctr: Int = 0
    
    override required init() { super.init() }
    
    required init(coder aDecoder: NSCoder) {
        page = aDecoder.decodeObject(forKey: "page") as? Int
        path = aDecoder.decodeObject(forKey: "path") as! UIBezierPath
        color = aDecoder.decodeObject(forKey: "color") as! UIColor
        fill = aDecoder.decodeBool(forKey: "fill")
        lineWidth = aDecoder.decodeObject(forKey: "lineWidth") as! CGFloat
        rect = aDecoder.decodeCGRect(forKey: "rect")
        points = aDecoder.decodeObject(forKey: "points") as! [CGPoint]
        incrementalImage = aDecoder.decodeObject(forKey: "image") as? UIImage
        ctr = aDecoder.decodeInteger(forKey: "ctr")
        
        super.init()
    }
    
    func drawRect(_ frame: CGRect) {
        self.incrementalImage?.draw(at: CGPoint.zero)
        self.color.setStroke()
        self.path.stroke()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(page, forKey: "page")
        aCoder.encode(path, forKey: "path")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(fill, forKey: "fill")
        aCoder.encode(lineWidth, forKey: "lineWidth")
        aCoder.encode(rect, forKey: "rect")
        aCoder.encode(points, forKey: "points")
        aCoder.encode(ctr, forKey: "ctr")
        aCoder.encode(incrementalImage, forKey: "image")
    }
}

class PDFPathView: ResizableView, PDFAnnotationView {
    var parent: PDFAnnotation?
    override var canBecomeFirstResponder: Bool { return true }
    
    convenience init(parent: PDFPathAnnotation, frame: CGRect) {
        
        self.init()
        
        self.frame = frame
        self.parent = parent
        
        backgroundColor = UIColor.clear
        isOpaque = false
        clipsToBounds = false
    }
    
    override func draw(_ rect: CGRect) {
        (parent as? PDFPathAnnotation)?.drawRect(rect)
    }
}

extension PDFPathAnnotation: PDFAnnotation {
    
    func mutableView() -> UIView {
        view = PDFPathView(parent: self, frame: rect)
        return view
    }
    
    func touchStarted(_ touch: UITouch, point: CGPoint) {
        ctr = 0
        points[0] = point
        path.move(to: points[0])
    }
    
    func touchMoved(_ touch: UITouch, point: CGPoint) {
        ctr += 1
        points[ctr] = point
        if ctr == 4 {
            points[3] = CGPoint(
                x: (points[2].x + points[4].x) / 2.0,
                y: (points[2].y + points[4].y) / 2.0
            )
            
            path.move(to: points[0])
            path.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            
            view.setNeedsDisplay()
            
            points[0] = points[3]
            points[1] = points[4]
            
            ctr = 1
        }
    }
    
    func touchEnded(_ touch: UITouch, point: CGPoint) {
        
        view.setNeedsDisplay()
        ctr = 0
    }
    
    func save() {
        
        let rect = path.bounds
        let inset: CGFloat = 5.0
        let translation = CGAffineTransform(translationX: -path.bounds.minX + inset,
                                            y: -path.bounds.minY + inset)
        path.apply(translation)
        
        print(self.rect)
        print(rect)
        self.rect = rect.insetBy(dx: -1 * inset, dy: -1 * inset)
        
        drawBitmap()
        view.setNeedsDisplay()
        ctr = 0
        
        self.saved = true
    }
    
    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        if incrementalImage == nil {
            let path = UIBezierPath(rect: rect)
            UIColor.clear.setFill()
            path.fill()
        }
        
        incrementalImage?.draw(at: CGPoint.zero)
        color.setStroke()
        path.stroke()
        incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func drawInContext(_ context: CGContext) {
        drawBitmap()
        drawRect(rect)
    }
}

extension PDFPathAnnotation: ResizableViewDelegate {
    func resizableViewDidBeginEditing(view: ResizableView) {
        //self.view.delegate?.annotationDidSelect(annotation: self)
        print("started editing")
    }
    func resizableViewDidEndEditing(view: ResizableView) {
        print("done editing")
    }
    func resizableViewDidSelectAction(view: ResizableView, action: String) {
        print(action)
    }
}

class PDFPenAnnotation: PDFPathAnnotation, PDFAnnotationButtonable {
    
    static var name: String? { return "Pen" }
    static var buttonImage: UIImage? { return UIImage.bundledImage("pen") }
}

class PDFHighlighterAnnotation: PDFPathAnnotation, PDFAnnotationButtonable {
    
    static var name: String? { return "Highlighter" }
    static var buttonImage: UIImage? { return UIImage.bundledImage("highlighter") }
    
    required init() {
        super.init()
        
        color = UIColor.yellow.withAlphaComponent(0.3)
        lineWidth = 10.0
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
