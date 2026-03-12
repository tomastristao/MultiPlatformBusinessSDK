import XCTest
@testable import BusinessSDK

final class BusinessSDKTests: XCTestCase {
    func testGeneratedModulesAreRegistered() {
        XCTAssertEqual(BusinessSDKExports.contractModules, ["ToggleIdentitySDK", "AdviceSlipSDK", "CatFactsSDK", "OpenBrewerySDK", "PokemonSDK", "RickAndMortySDK"])
    }
}
