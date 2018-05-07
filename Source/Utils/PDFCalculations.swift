//
//  PDFCalculations.swift
//  TPPDF
//
//  Created by Philip Niedertscheider on 24/08/2017.
//

// swiftlint:disable function_body_length

/**
 A collection of static calculations
 */
class PDFCalculations {

    // MARK: - INTERNAL STATIC FUNCS

    /**
     Calculates the frame, the string that fits in the given `container` and the remainding string.

     - parameter generator: Generator which is calculating
     - parameter container: Container where text is drawn
     - parameter text: Text which should be calculated and drawn

     - returns: Tuple of text `frame`, text which fits in frame and the remainding text which did not fit
     */
    static func calculateText(generator: PDFGenerator,
                              container: PDFContainer,
                              text: NSAttributedString) -> (frame: CGRect, render: NSAttributedString, remainder: NSAttributedString?) {
        let availableSize = calculateAvailableFrame(for: generator, in: container)
        let (fittingText, textSize, remainder) = calculateTextSizeAndRemainder(of: text, in: availableSize)
        let origin = calculateElementPosition(for: generator, in: container, with: textSize)

        return (
            CGRect(origin: origin, size: textSize),
            fittingText,
            remainder
        )
    }

    /**
     Calculates the actual size of the text and the remainder which does not fit the given `bounds`

     - parameter text: Text which is calculated
     - paramter bounds: Bounds where text should fit

     - returns: Tuple of `text`, real `size of the text and the `remainder`
     */
    static func calculateTextSizeAndRemainder(of text: NSAttributedString,
                                              in bounds: CGSize) -> (text: NSAttributedString, size: CGSize, remainder: NSAttributedString?) {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let framePath = UIBezierPath(rect: CGRect(origin: .zero, size: bounds)).cgPath

        let textRange = CFRange(location: 0, length: text.length)

        // Get the frame that will do the rendering
        let frameRef = CTFramesetterCreateFrame(framesetter, textRange, framePath, nil)

        // Calculate the range of the string which actually fits in the frame
        let visibleRange = CTFrameGetVisibleStringRange(frameRef)

        // Calculate the actual size the string needs
        let drawnSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, visibleRange, nil, bounds, nil)

        let castedRange = NSRange(location: 0, length: visibleRange.length)
        let result = text.attributedSubstring(from: castedRange)
        var remainder: NSAttributedString?

        if visibleRange.length != textRange.length {
            let remainderRange = NSRange(location: visibleRange.length, length: textRange.length - visibleRange.length)
            remainder = text.attributedSubstring(from: remainderRange)
        }

        return (result, drawnSize, remainder)
    }

    /**
     Calculates the available bounds size in a given `container`

     - parameter generator: Generator doing the calculations
     - parameter container: Container which size is calculated

     - returns: Available bounds size
     */
    static func calculateAvailableFrame(for generator: PDFGenerator, in container: PDFContainer) -> CGSize {
        return CGSize(
            width: calculateAvailableFrameWidth(for: generator, in: container),
            height: calculateAvailableFrameHeight(for: generator, in: container)
        )
    }

    /**
     Calculates the position of an element with given `size` in the given `container

     - parameter generator: Generator doing the calculations
     - parameter container: Container where element is in
     - parameter size: Size of element

     - returns: Position of element
     */
    static func calculateElementPosition(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGPoint {
        return CGPoint(
            x: calculatePositionX(for: generator, in: container, with: size),
            y: calculatePositionY(for: generator, in: container, with: size)
        )
    }

    // MARK: - PRIVATE STATIC FUNCS

    private static func calculateAvailableFrameWidth(for generator: PDFGenerator, in container: PDFContainer) -> CGFloat {
        let pageLayout = generator.document.layout

        return pageLayout.contentSize.width
            - generator.layout.indentation.leftIn(container: container)
            - generator.layout.indentation.rightIn(container: container)
    }

    private static func calculateAvailableFrameHeight(for generator: PDFGenerator, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader || container.isFooter {
            return pageLayout.height
        } else {
            return pageLayout.contentSize.height
                - layout.heights.maxHeaderHeight()
                - pageLayout.space.header
                - layout.heights.content
                - pageLayout.space.footer
                - layout.heights.maxFooterHeight()
        }
    }

    private static func calculatePositionX(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isLeft {
            return pageLayout.margin.left
                + layout.indentation.leftIn(container: container)
        } else if container.isRight {
            return pageLayout.width
                - pageLayout.margin.right
                - layout.indentation.rightIn(container: container)
                - size.width
        } else {
            return pageLayout.margin.left
                + layout.indentation.leftIn(container: container)
                + (pageLayout.contentSize.width
                    - layout.indentation.leftIn(container: container)
                    - layout.indentation.rightIn(container: container)
                    - size.width
                ) / 2
        }
    }

    private static func calculatePositionY(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return pageLayout.margin.top
                + layout.heights.value(for: container)
        } else if container.isFooter {
            return pageLayout.height
                - pageLayout.margin.bottom
                - layout.heights.value(for: container)
                - size.height
        } else {
            return pageLayout.margin.top
                + layout.heights.maxHeaderHeight()
                + pageLayout.space.header
                + layout.heights.content
        }
    }

    static func calculateContentOffset(for generator: PDFGenerator, of element: PDFObject, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return element.frame.minY
                - pageLayout.margin.top
        } else if container.isFooter {
            return element.frame.minY
                - (pageLayout.height
                    - pageLayout.margin.bottom
                    - layout.heights.value(for: container)
                    - element.frame.height)
        } else {
            return element.frame.minY
                - pageLayout.margin.top
                - layout.heights.maxHeaderHeight()
                - pageLayout.space.header
        }
    }

    static func calculateContentOffset(for generator: PDFGenerator, of offset: CGFloat, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return offset
                - pageLayout.margin.top
        } else if container.isFooter {
            return offset
                - (pageLayout.height
                    - pageLayout.margin.bottom
                    - layout.heights.value(for: container))
        } else {
            return offset
                - pageLayout.margin.top
                - layout.heights.maxHeaderHeight()
                - pageLayout.space.header
        }
    }

    // MARK: - LEGACY

    static func calculateCellFrame(generator: PDFGenerator,
                                   container: PDFContainer,
                                   position: (origin: CGPoint, width: CGFloat),
                                   text: NSAttributedString,
                                   alignment: PDFTableCellAlignment) -> CGRect {
        //let textMaxHeight = PDFCalculations.calculateAvailableFrameHeight(for: generator, in: container)
        //let frame: CGRect = CGRect(x: position.origin.x, y: position.origin.y, width: position.width, height: textMaxHeight)

		// We're about to calculate the text box frame. Originally (above), we said
		// "calculate the frame of this text, but make sure it fits inside this box -
		// with a particular width and height".
		// We need the width constrained as the horizontal area we allow our text is
		// finite.
		// The issue here was the height — the calculateTextFrameAndDrawnSizeInOnePage
		// method says "if the text you've passed in exceeds the given frame, I'm just going
		// to assume we're truncating the text, and give you the frame that fits the
		// truncated text". That would be fantastic (and allow us to split huge volumes
		// of text across pages), but the problem is that truncation is never communicated
		// further. The text is truncated, and no one knows.
		// Therefore, it would render this truncated text, and just go on rendering
		// the next block it finds.
		// Keeping this truncation is in the too-hard-basket for now. Instead,
		// we're just going to assume we have near-infinite height in which to store our
		// text so the frame is calculated for the _entire_ text.
		// The calling methods eventually work out that it's going to need to fit
		// on the next page, and everything just works.
        let frame: CGRect = CGRect(x: position.origin.x, y: position.origin.y, width: position.width, height: CGFloat.greatestFiniteMagnitude)
		let drawnSize = calculateSizeForText(in: frame, text: text)

        //let currentRange = CFRange(location: 0, length: 0)
        //let (_, _, anotherSize) = calculateTextFrameAndDrawnSizeInOnePage(frame: frame, text: text, currentRange: currentRange)

		let x: CGFloat = {
            if alignment.isLeft {
                return position.origin.x
            } else if alignment.isRight {
                return position.origin.x + position.width - drawnSize.width
            } else {
                return position.origin.x + position.width / 2 - drawnSize.width / 2
            }
        }()

        return CGRect(origin: CGPoint(x: x, y: position.origin.y), size: CGSize(width: drawnSize.width, height: drawnSize.height))
    }

    static func calculateCellFrame(generator: PDFGenerator, origin: CGPoint, width: CGFloat, image: UIImage) -> CGRect {
        let imageSize = image.size
        let height = imageSize.height / imageSize.width * width

        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }

    static func calculateTextFrameAndDrawnSizeInOnePage(generator: PDFGenerator,
                                                        container: PDFContainer,
                                                        text: CFAttributedString,
                                                        currentRange: CFRange,
                                                        textMaxWidth: CGFloat) -> (CGRect, CTFrame, CGSize) {
        let textMaxWidth = (textMaxWidth > 0) ? textMaxWidth : (generator.document.layout.width
            - generator.document.layout.margin.left
            - generator.document.layout.margin.right
            - generator.layout.indentation.leftIn(container: container)
            - generator.layout.indentation.rightIn(container: container))

        let textMaxHeight: CGFloat = {
            if container.isHeader {
                return generator.document.layout.height
                    - generator.layout.heights.header[container]!
            } else if container.isFooter {
                return generator.document.layout.margin.bottom
            } else {
                return generator.document.layout.height
                    - generator.layout.heights.maxHeaderHeight()
                    - generator.document.layout.space.header
                    - generator.layout.heights.maxFooterHeight()
                    - generator.document.layout.space.footer
                    - generator.layout.heights.content
            }
        }()

        // Create a path object to enclose the text.
        let x: CGFloat = {
            switch container {
            case .headerLeft, .contentLeft, .footerLeft:
                return generator.document.layout.margin.left
                    + generator.layout.indentation.leftIn(container: container)
            case .headerCenter, .contentCenter, .footerCenter:
                return generator.document.layout.bounds.midX
                    - textMaxWidth / 2
            case .headerRight, .contentRight, .footerRight:
                return generator.document.layout.width
                    - generator.document.layout.margin.right
                    - textMaxWidth
            default:
                return 0
            }
        }()

        let frame: CGRect = {
            if container.isHeader {
                return CGRect(x: x,
                              y: 0,
                              width: textMaxWidth,
                              height: textMaxHeight)
            } else if container.isFooter {
                return CGRect(x: x,
                              y: generator.document.layout.height
                                - generator.layout.heights.footer[container]!,
                              width: textMaxWidth,
                              height: textMaxHeight)
            } else {
                return CGRect(x: x,
                              y: generator.layout.heights.content
                                + generator.layout.heights.maxHeaderHeight()
                                + generator.document.layout.space.header,
                              width: textMaxWidth,
                              height: textMaxHeight)
            }
        }()

        return calculateTextFrameAndDrawnSizeInOnePage(frame: frame, text: text, currentRange: currentRange)
    }

	static func calculateSizeForText(in frame: CGRect, text: NSAttributedString) -> CGSize {
		guard text.length > 0 else {
			return CGSize(width: 0, height: 0)
		}
		let ts = NSTextStorage(attributedString: text)
		let size = CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude)
		let tc = NSTextContainer(size: size)
		tc.lineFragmentPadding = 0.0
		let lm = NSLayoutManager()
		lm.addTextContainer(tc)
		ts.addLayoutManager(lm)
		lm.glyphRange(forBoundingRect: CGRect(origin: CGPoint(x: 0, y: 0), size: size), in: tc)
		let rect = lm.usedRect(for: tc)
		return CGSize(width: ceil(rect.size.width), height: ceil(rect.size.height + 1)) // adjusted slightly as we're 1 off
	}

    static func calculateTextFrameAndDrawnSizeInOnePage(frame: CGRect, text: CFAttributedString, currentRange: CFRange) -> (CGRect, CTFrame, CGSize) {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let framePath = UIBezierPath(rect: frame).cgPath

        // Get the frame that will do the rendering.
        // The currentRange variable specifies only the starting point. The framesetter
        // lays out as much text as will fit into the frame.
        let frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)

        // Update the current range based on what was drawn.
        let visibleRange = CTFrameGetVisibleStringRange(frameRef)

        // Update last drawn frame
        let drawnSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, visibleRange, nil, frame.size, nil)

        return (frame, frameRef, drawnSize)
    }

    static func calculateImageCaptionSize(generator: PDFGenerator,
                                          container: PDFContainer,
                                          image: PDFImage,
                                          size: CGSize,
                                          sizeFit: PDFImageSizeFit) -> (CGSize, CGSize) {
        /* calculate the aspect size of image */
        let size = (size == CGSize.zero) ? image.size : size

        let maxWidth = min(size.width, calculateAvailableFrameWidth(for: generator, in: container))
        let maxHeight = min(size.height, calculateAvailableFrameHeight(for: generator, in: container))

        let wFactor = image.size.width / maxWidth
        let hFactor = image.size.height / maxHeight

        let factor: CGFloat = {
            switch sizeFit {
            case .width:
                return wFactor
            case .height:
                return hFactor
            case .widthHeight:
                return max(wFactor, hFactor)
            }
        }()

        let imageSize = CGSize(width: image.size.width / factor, height: image.size.height / factor)
        return (imageSize, CGSize(width: imageSize.width, height: 0))
    }

}
