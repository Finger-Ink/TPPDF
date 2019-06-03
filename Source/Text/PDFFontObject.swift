//
//  PDFFontObject.swift
//  TPPDF
//
//  Created by Philip Niedertscheider on 12/08/2017.
//

/**
 Changes the font of the container, where this object is in.
 */
class PDFFontObject: PDFObject {

    /**
     New font of container after calculation
     */
    var font: UIFont

    /**
     Initalizer

     - parameter font: New font
     */
    init(font: UIFont) {
        self.font = font
    }

    /**
     Sets the font in `container`

     - parameter generator: Generator which holds font information
     - parameter container: Container, where the font is changed

     - throws: None

     - returns: Self
     */
    override func calculate(generator: PDFGenerator, container: PDFContainer) throws -> [(PDFContainer, PDFObject)] {
        generator.fonts[container] = font

        return [(container, self)]
    }

    /**
     Creates a new `PDFFontObject` with the same properties
     */
    override var copy: PDFObject {
        return PDFFontObject(font: self.font)
    }
}

extension PDFFontObject: CustomDebugStringConvertible {

    var debugDescription: String {
        return "PDFFontObject(font: \(font.debugDescription))"
    }
}

extension PDFFontObject: CustomStringConvertible {

    var description: String {
        return "PDFFontObject(font: \(font.description))"
    }
}
