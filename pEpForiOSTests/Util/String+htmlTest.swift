//
//  String+htmlTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 27/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class String_htmlTest: XCTestCase {

    func testExternalContent() throws {
        var externalContent = htmlWithExternalContent.containsExternalContent()
        XCTAssertTrue(externalContent)
        externalContent = htmlWithoutExternalContent.containsExternalContent()
        XCTAssertFalse(externalContent)
    }

}

extension String_htmlTest {
    //this string contains 5 different img tags with external content.
    var htmlWithExternalContent: String {
        return """
        <img src=3D"www.iberdrola.=es/02sica/ngc/img/FE_ES/logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        <img src=3D"http://www.iberdrola.=es/02sica/ngc/img/FE_ES/logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        <img src=3D"https://www.iberdrola.=es/02sica/ngc/img/FE_ES/logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        <img src=3D"https://iberdrola.=es/02sica/ngc/img/FE_ES/logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        <img src=3D"http://iberdrola.=es/02sica/ngc/img/FE_ES/logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        """
    }
    
    var htmlWithoutExternalContent: String {
        return """
        <img src=3D"CID:logo.png" alt=3D"" width=3D"172" height=3D"40" st=yle=3D"width:172px; height:40px; display: block">
        """
    }
}
