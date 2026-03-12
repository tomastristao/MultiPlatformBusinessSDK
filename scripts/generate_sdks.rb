#!/usr/bin/env ruby

require "fileutils"
require "yaml"

ROOT = File.expand_path(ENV.fetch("SDK_ROOT", File.join(__dir__, "..")))
CONTRACTS_DIR = File.expand_path(ENV.fetch("SDK_CONTRACTS_DIR", File.join(ROOT, "contracts")))
IOS_DIR = File.join(ROOT, "BusinessSDK")
IOS_SOURCES_DIR = File.join(IOS_DIR, "Sources")
IOS_TESTS_DIR = File.join(IOS_DIR, "Tests", "BusinessSDKTests")
ANDROID_DIR = File.join(ROOT, "android")
ANDROID_MODULES_DIR = File.join(ANDROID_DIR, "modules")
ANDROID_UMBRELLA_DIR = File.join(ANDROID_DIR, "business-sdk")
DOCS_DIR = File.join(ROOT, "docs", "generated")
ANDROID_GROUP_ID = "com.multiplatformbusinesssdk"

PRIMITIVE_SWIFT_TYPES = %w[String Int Double Bool].freeze
PRIMITIVE_KOTLIN_TYPES = {
  "String" => "String",
  "Int" => "Int",
  "Double" => "Double",
  "Bool" => "Boolean"
}.freeze

def read_contracts
  Dir.glob(File.join(CONTRACTS_DIR, "*.{yml,yaml}")).sort.map do |path|
    contract = YAML.load_file(path)
    contract["source_file"] = path
    contract
  end
end

def ensure_dir(path)
  FileUtils.mkdir_p(path)
end

def write_file(path, content)
  ensure_dir(File.dirname(path))
  File.write(path, content)
end

def format_dependency_array(entries)
  "[#{entries.join(', ')}]"
end

def pascal_case(value)
  value.to_s.split(/[^a-zA-Z0-9]+|(?=[A-Z])/).reject(&:empty?).map(&:capitalize).join
end

def lower_camel_case(value)
  pascal = pascal_case(value)
  return pascal if pascal.empty?

  pascal[0].downcase + pascal[1..]
end

def list_type?(type)
  type.start_with?("[") && type.end_with?("]")
end

def unwrap_list(type)
  type[1..-2]
end

def swift_default_value(param)
  return nil unless param.key?("default")

  value = param["default"]
  case param["type"]
  when "String"
    "\"#{value}\""
  when "Bool"
    value ? "true" : "false"
  else
    value.to_s
  end
end

def kotlin_default_value(param)
  return nil unless param.key?("default")

  value = param["default"]
  case param["type"]
  when "String"
    "\"#{value}\""
  when "Bool"
    value ? "true" : "false"
  else
    value.to_s
  end
end

def swift_literal(value, type)
  case type
  when "String"
    "\"#{value}\""
  when "Bool"
    value ? "true" : "false"
  else
    value.to_s
  end
end

def kotlin_string_expression(param)
  case param["type"]
  when "String"
    param["name"]
  when "Bool"
    "#{param["name"]}.toString()"
  else
    "#{param["name"]}.toString()"
  end
end

def swift_path_expression(path, params)
  expression = "\"#{path}\""
  (params || []).each do |param|
    placeholder = "{#{param["name"]}}"
    expression = expression.sub(placeholder, "\\(#{param["name"]})")
  end
  expression
end

def kotlin_path_expression(path, params)
  quoted = "\"#{path}\""
  (params || []).each do |param|
    quoted = quoted.gsub("{#{param["name"]}}", "$#{param["name"]}")
  end
  quoted
end

def render_swift_query_items(params)
  return "[]" if params.nil? || params.empty?

  items = params.map do |param|
    "URLQueryItem(name: \"#{param["name"]}\", value: String(describing: #{param["name"]}))"
  end
  "[#{items.join(', ')}]"
end

def render_kotlin_query_map(params)
  return "emptyMap()" if params.nil? || params.empty?

  entries = params.map do |param|
    "\"#{param["name"]}\" to #{kotlin_string_expression(param)}"
  end
  "mapOf(\n            #{entries.join(",\n            ")}\n        )"
end

def swift_target_names(contracts)
  ["BusinessSDKCore", "BusinessSDK"] + contracts.map { |contract| contract.fetch("swift_module") }
end

def cleanup_generated_directories(contracts)
  keep_ios = ["BusinessSDKCore", "BusinessSDK"] + contracts.map { |contract| contract.fetch("swift_module") }
  Dir.children(IOS_SOURCES_DIR).each do |entry|
    next if keep_ios.include?(entry)

    FileUtils.rm_rf(File.join(IOS_SOURCES_DIR, entry))
  end

  ensure_dir(ANDROID_MODULES_DIR)
  Dir.children(ANDROID_MODULES_DIR).each do |entry|
    FileUtils.rm_rf(File.join(ANDROID_MODULES_DIR, entry))
  end

  FileUtils.rm_rf(ANDROID_UMBRELLA_DIR)
end

def android_publish_snippet(artifact_id, pom_name, pom_description)
  <<~KOTLIN

    afterEvaluate {
        publishing {
            publications {
                create("release", org.gradle.api.publish.maven.MavenPublication::class) {
                    from(components["release"])
                    groupId = "#{ANDROID_GROUP_ID}"
                    artifactId = "#{artifact_id}"
                    version = System.getenv("SDK_VERSION") ?: "0.1.0-SNAPSHOT"

                    pom {
                        name.set("#{pom_name}")
                        description.set("#{pom_description}")
                    }
                }
            }

            repositories {
                maven {
                    name = "GitHubPackages"
                    val repository = System.getenv("GITHUB_REPOSITORY") ?: "OWNER/REPO"
                    url = uri("https://maven.pkg.github.com/$repository")
                    credentials {
                        username = System.getenv("GITHUB_ACTOR")
                        password = System.getenv("GITHUB_TOKEN")
                    }
                }
            }
        }
    }
  KOTLIN
end

def generate_contract_docs(contracts)
  sections = contracts.map do |contract|
    repositories = contract.fetch("repositories").map do |repository|
      methods = repository.fetch("methods").map do |method|
        params = Array(method["path_params"]) + Array(method["query_params"])
        signature = if params.empty?
          method.fetch("name")
        else
          "#{method.fetch("name")}(#{params.map { |param| "#{param["name"]}: #{param["type"]}" }.join(", ")})"
        end

        "- `#{signature}` -> `#{method.fetch("method")} #{method.fetch("path")}` -> `#{method.fetch("response")}`"
      end.join("\n")

      <<~MARKDOWN
        ### #{repository.fetch("name")}

        - Swift access: `let repo = #{contract.fetch("swift_module")}Client().#{lower_camel_case(repository.fetch("name"))}`
        - Kotlin access: `val repo = #{contract.fetch("swift_module")}Client().#{lower_camel_case(repository.fetch("name"))}`

        #{methods}
      MARKDOWN
    end.join("\n")

    <<~MARKDOWN
      ## #{contract.fetch("name")}

      - Contract file: `#{File.basename(contract.fetch("source_file"))}`
      - Swift module: `#{contract.fetch("swift_module")}`
      - Android module: `#{contract.fetch("android_module")}`
      - Android package: `#{contract.fetch("android_package")}`
      - Base URL: `#{contract.fetch("base_url")}`
      - Client: `#{contract.fetch("swift_module")}Client`

      #{repositories}
    MARKDOWN
  end.join("\n")

  body = if contracts.empty?
    <<~MARKDOWN
      The SDK is currently empty.

      Add a contract file to `contracts/` and rerun `ruby scripts/generate_sdks.rb` to generate iOS and Android repositories plus this document.
    MARKDOWN
  else
    sections
  end

  <<~MARKDOWN
    # Generated SDK Catalog

    This file is generated by `scripts/generate_sdks.rb`.

    - Total contracts: `#{contracts.size}`
    - Generated Swift package: `BusinessSDK/`
    - Generated Android modules: `android/`
    - Android GitHub package: `#{ANDROID_GROUP_ID}:business-sdk-android:<branch-slug>`

    ## Android Consumption

    Add GitHub Packages:

    ```kotlin
    repositories {
        maven {
            url = uri("https://maven.pkg.github.com/<OWNER>/<REPO>")
            credentials {
                username = providers.gradleProperty("gpr.user").orNull
                password = providers.gradleProperty("gpr.key").orNull
            }
        }
    }
    ```

    Consume the umbrella package:

    ```kotlin
    dependencies {
        implementation("#{ANDROID_GROUP_ID}:business-sdk-android:<branch-slug>")
    }
    ```

    #{body}
  MARKDOWN
end

def generate_package_swift(contracts, source_root: nil, tests_root: nil)
  products = [
    <<~PRODUCT.chomp
      .library(
                  name: "BusinessSDK",
                  targets: ["BusinessSDK"]
              ),
    PRODUCT
  ]

  contracts.each do |contract|
    name = contract.fetch("swift_module")
    products << <<~PRODUCT.chomp
      .library(
                  name: "#{name}",
                  targets: ["#{name}"]
              ),
    PRODUCT
  end

  contract_targets = contracts.map do |contract|
    name = contract.fetch("swift_module")
    target_path = source_root ? ",\n                path: \"#{source_root}/#{name}\"" : ""
    <<~TARGET.chomp
      .target(
                  name: "#{name}",
                  dependencies: ["BusinessSDKCore"]#{target_path}
              ),
    TARGET
  end

  test_dependencies = ["\"BusinessSDK\""] + contracts.map { |contract| "\"#{contract.fetch("swift_module")}\"" }

  business_sdk_dependencies = ["\"BusinessSDKCore\""] + contracts.map { |contract| "\"#{contract.fetch("swift_module")}\"" }
  core_path = source_root ? ",\n            path: \"#{source_root}/BusinessSDKCore\"" : ""
  business_path = source_root ? ",\n            path: \"#{source_root}/BusinessSDK\"" : ""
  tests_path = tests_root ? ",\n            path: \"#{tests_root}/BusinessSDKTests\"" : ""

  <<~SWIFT
    // swift-tools-version: 6.2

    import PackageDescription

    let package = Package(
        name: "BusinessSDK",
        platforms: [
            .iOS(.v16),
            .macOS(.v13)
        ],
        products: [
    #{products.map { |line| "        #{line}" }.join("\n")}
        ],
        targets: [
            .target(
                name: "BusinessSDKCore"#{core_path}
            ),
    #{contract_targets.map { |line| "        #{line}" }.join("\n")}
            .target(
                name: "BusinessSDK",
                dependencies: #{format_dependency_array(business_sdk_dependencies)}#{business_path}
            ),
            .testTarget(
                name: "BusinessSDKTests",
                dependencies: #{format_dependency_array(test_dependencies)}#{tests_path}
            )
        ]
    )
  SWIFT
end

def generate_swift_core
  <<~SWIFT
    import Foundation

    public enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    public protocol APIRequest: Sendable {
        associatedtype Response: Decodable & Sendable

        var path: String { get }
        var method: HTTPMethod { get }
        var body: Data? { get }
        var headers: [String: String] { get }
        var queryItems: [URLQueryItem] { get }
        var requiresAuthorization: Bool { get }
    }

    public enum NetworkError: Error, Sendable {
        case url(URLError)
        case invalidResponse
        case unauthorized
        case httpStatus(code: Int, data: Data)
        case noData
        case decoding(Error)
    }

    public protocol SecurityKitProtocol: Sendable {
        func getAccessToken() async -> String?
        func refreshAccessToken() async throws
        func clearTokens() async
    }

    public actor NoOpSecurityKit: SecurityKitProtocol {
        public init() {}

        public func getAccessToken() async -> String? { nil }
        public func refreshAccessToken() async throws {}
        public func clearTokens() async {}
    }

    public actor RefreshGate {
        public init() {}

        public func refreshIfNeeded(_ operation: @Sendable () async throws -> Void) async throws {
            try await operation()
        }
    }

    public protocol NetworkEngineProtocol: Sendable {
        func request<T: APIRequest>(_ requestConfig: T) async throws -> T.Response
    }

    public final class NetworkEngine: NetworkEngineProtocol, @unchecked Sendable {
        private let baseURL: URL
        private let session: URLSession
        private let security: SecurityKitProtocol
        private let decoder: JSONDecoder
        private let refreshGate: RefreshGate

        public init(
            baseURL: URL,
            security: SecurityKitProtocol = NoOpSecurityKit(),
            session: URLSession = .shared,
            decoder: JSONDecoder = .init(),
            refreshGate: RefreshGate = RefreshGate()
        ) {
            self.baseURL = baseURL
            self.security = security
            self.session = session
            self.decoder = decoder
            self.refreshGate = refreshGate
        }

        public func request<T: APIRequest>(_ requestConfig: T) async throws -> T.Response {
            let url = try makeURL(for: requestConfig)
            var request = URLRequest(url: url)
            request.httpMethod = requestConfig.method.rawValue
            request.httpBody = requestConfig.body

            requestConfig.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

            if requestConfig.requiresAuthorization, let token = await security.getAccessToken() {
                request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
            }

            return try await perform(request, as: T.self, didRetryAfterRefresh: false)
        }

        private func makeURL<T: APIRequest>(for requestConfig: T) throws -> URL {
            let endpoint = requestConfig.path.hasPrefix("/") ? String(requestConfig.path.dropFirst()) : requestConfig.path
            let url = baseURL.appendingPathComponent(endpoint)

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw NetworkError.invalidResponse
            }

            if !requestConfig.queryItems.isEmpty {
                components.queryItems = requestConfig.queryItems
            }

            guard let finalURL = components.url else {
                throw NetworkError.invalidResponse
            }

            return finalURL
        }

        private func perform<T: APIRequest>(
            _ request: URLRequest,
            as _: T.Type,
            didRetryAfterRefresh: Bool
        ) async throws -> T.Response {
            let data: Data
            let response: URLResponse

            do {
                (data, response) = try await session.data(for: request)
            } catch let error as URLError {
                throw NetworkError.url(error)
            } catch {
                throw error
            }

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            if http.statusCode == 401 {
                if didRetryAfterRefresh {
                    await security.clearTokens()
                    throw NetworkError.unauthorized
                }

                let hadAuthHeader = request.value(forHTTPHeaderField: "Authorization") != nil
                guard hadAuthHeader else {
                    throw NetworkError.unauthorized
                }

                do {
                    try await refreshGate.refreshIfNeeded {
                        try await self.security.refreshAccessToken()
                    }
                } catch {
                    await security.clearTokens()
                    throw NetworkError.unauthorized
                }

                guard let newToken = await security.getAccessToken() else {
                    await security.clearTokens()
                    throw NetworkError.unauthorized
                }

                var retry = request
                retry.setValue("Bearer \\(newToken)", forHTTPHeaderField: "Authorization")
                return try await perform(retry, as: T.self, didRetryAfterRefresh: true)
            }

            guard (200...299).contains(http.statusCode) else {
                throw NetworkError.httpStatus(code: http.statusCode, data: data)
            }

            guard !data.isEmpty else {
                throw NetworkError.noData
            }

            do {
                return try decoder.decode(T.Response.self, from: data)
            } catch {
                throw NetworkError.decoding(error)
            }
        }
    }
  SWIFT
end

def swift_structs(contract)
  contract.fetch("models").map do |model|
    fields = model.fetch("fields").map { |field| "    public let #{field["name"]}: #{field["type"]}" }.join("\n")
    init_params = model.fetch("fields").map { |field| "#{field["name"]}: #{field["type"]}" }.join(", ")
    assignments = model.fetch("fields").map { |field| "        self.#{field["name"]} = #{field["name"]}" }.join("\n")

    <<~SWIFT
      public struct #{model.fetch("name")}: Codable, Sendable {
      #{fields}

          public init(#{init_params}) {
      #{assignments}
          }
      }
    SWIFT
  end.join("\n")
end

def swift_repository(contract)
  repositories = contract.fetch("repositories")
  headers = contract.fetch("default_headers", {})
  base_url_literal = "\"#{contract.fetch("base_url")}\""

  request_structs = repositories.flat_map do |repository|
    repository.fetch("methods").map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      init_params = params.map do |param|
        default = swift_default_value(param)
        default ? "#{param["name"]}: #{param["type"]} = #{default}" : "#{param["name"]}: #{param["type"]}"
      end.join(", ")
      assignments = params.map { |param| "        self.#{param["name"]} = #{param["name"]}" }.join("\n")
      stored_properties = params.map { |param| "    private let #{param["name"]}: #{param["type"]}" }.join("\n")
      path_expression = swift_path_expression(method.fetch("path"), method["path_params"])
      header_entries = headers.map { |key, value| "\"#{key}\": #{swift_literal(value, "String")}" }.join(", ")
      header_body = header_entries.empty? ? "[:]" : "[#{header_entries}]"
      request_name = "#{repository.fetch("name")}#{pascal_case(method.fetch("name"))}Request"

      <<~SWIFT
        private struct #{request_name}: APIRequest {
        #{stored_properties}

            init(#{init_params}) {
        #{assignments unless assignments.empty?}
            }

            let method: HTTPMethod = .#{method.fetch("method").downcase}
            let body: Data? = nil
            let headers: [String: String] = #{header_body}
            let requiresAuthorization: Bool = #{method.fetch("requires_authorization", false) ? "true" : "false"}

            var path: String {
                #{path_expression}
            }

            var queryItems: [URLQueryItem] {
                #{render_swift_query_items(method["query_params"])}
            }

            typealias Response = #{method.fetch("response")}
        }
      SWIFT
    end
  end.join("\n")

  repository_types = repositories.map do |repository|
    methods = repository.fetch("methods")

    protocol_methods = methods.map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      signature = params.map { |param| "#{param["name"]}: #{param["type"]}" }.join(", ")
      "    func #{method.fetch("name")}(#{signature}) async throws -> #{method.fetch("response")}"
    end.join("\n")

    impl_methods = methods.map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      signature = params.map do |param|
        default = swift_default_value(param)
        default ? "#{param["name"]}: #{param["type"]} = #{default}" : "#{param["name"]}: #{param["type"]}"
      end.join(", ")
      invocation = params.map { |param| "#{param["name"]}: #{param["name"]}" }.join(", ")
      request_name = "#{repository.fetch("name")}#{pascal_case(method.fetch("name"))}Request"

      <<~SWIFT
        public func #{method.fetch("name")}(#{signature}) async throws -> #{method.fetch("response")} {
            try await networkEngine.request(#{request_name}(#{invocation}))
        }
      SWIFT
    end.join("\n")

    <<~SWIFT
      public protocol #{repository.fetch("name")}Protocol: Sendable {
      #{protocol_methods}
      }

      public final class #{repository.fetch("name")}: #{repository.fetch("name")}Protocol, @unchecked Sendable {
          private let networkEngine: NetworkEngineProtocol

          public init(networkEngine: NetworkEngineProtocol) {
              self.networkEngine = networkEngine
          }

      #{impl_methods}
      }
    SWIFT
  end.join("\n")

  sdk_protocol_properties = repositories.map do |repository|
    "    var #{lower_camel_case(repository.fetch("name"))}: #{repository.fetch("name")}Protocol { get }"
  end.join("\n")

  sdk_impl_properties = repositories.map do |repository|
    "    public let #{lower_camel_case(repository.fetch("name"))}: #{repository.fetch("name")}Protocol"
  end.join("\n")

  sdk_assignments = repositories.map do |repository|
    property_name = lower_camel_case(repository.fetch("name"))
    "        self.#{property_name} = #{repository.fetch("name")}(networkEngine: networkEngine)"
  end.join("\n")

  <<~SWIFT
    import Foundation
    import BusinessSDKCore

    public enum #{contract.fetch("swift_module")}Config {
        public static let baseURL = URL(string: #{base_url_literal})!
    }

    #{swift_structs(contract)}

    #{request_structs}

    #{repository_types}

    public protocol #{contract.fetch("swift_module")}ClientProtocol: Sendable {
    #{sdk_protocol_properties}
    }

    public struct #{contract.fetch("swift_module")}Client: #{contract.fetch("swift_module")}ClientProtocol, Sendable {
    #{sdk_impl_properties}

        public init(networkEngine: NetworkEngineProtocol = NetworkEngine(baseURL: #{contract.fetch("swift_module")}Config.baseURL)) {
    #{sdk_assignments}
        }
    }
  SWIFT
end

def generate_swift_umbrella(contracts)
  exports = (["BusinessSDKCore"] + contracts.map { |contract| contract.fetch("swift_module") }).map do |module_name|
    "@_exported import #{module_name}"
  end.join("\n")
  module_names = format_dependency_array(contracts.map { |contract| "\"#{contract.fetch("swift_module")}\"" })

  <<~SWIFT
    #{exports}

    public enum BusinessSDKExports {
        public static let contractModules: [String] = #{module_names}
    }
  SWIFT
end

def generate_tests(contracts)
  expected_modules = format_dependency_array(contracts.map { |contract| "\"#{contract.fetch("swift_module")}\"" })

  <<~SWIFT
    import XCTest
    @testable import BusinessSDK

    final class BusinessSDKTests: XCTestCase {
        func testGeneratedModulesAreRegistered() {
            XCTAssertEqual(BusinessSDKExports.contractModules, #{expected_modules})
        }
    }
  SWIFT
end

def kotlin_type(type)
  return "List<#{kotlin_type(unwrap_list(type))}>" if list_type?(type)

  PRIMITIVE_KOTLIN_TYPES.fetch(type, type)
end

def primitive_array_accessor(type, array_name, index_name)
  case type
  when "String"
    "#{array_name}.getString(#{index_name})"
  when "Int"
    "#{array_name}.getInt(#{index_name})"
  when "Double"
    "#{array_name}.getDouble(#{index_name})"
  when "Bool"
    "#{array_name}.getBoolean(#{index_name})"
  else
    raise "Unsupported primitive array type: #{type}"
  end
end

def kotlin_model_field_parser(field)
  type = field.fetch("type")
  name = field.fetch("name")

  if list_type?(type)
    inner = unwrap_list(type)
    item_parser = if PRIMITIVE_KOTLIN_TYPES.key?(inner)
      primitive_array_accessor(inner, "array", "index")
    else
      "#{inner}.fromJson(array.getJSONObject(index))"
    end

    <<~KOTLIN.chomp
      val #{name}Array = json.getJSONArray("#{name}")
                  val #{name} = buildList {
                      for (index in 0 until #{name}Array.length()) {
                          add(#{item_parser.gsub("array", "#{name}Array")})
                      }
                  }
    KOTLIN
  else
    accessor = case type
               when "String"
                 "json.getString(\"#{name}\")"
               when "Int"
                 "json.getInt(\"#{name}\")"
               when "Double"
                 "json.getDouble(\"#{name}\")"
               when "Bool"
                 "json.getBoolean(\"#{name}\")"
               else
                 "#{type}.fromJson(json.getJSONObject(\"#{name}\"))"
               end
    "val #{name} = #{accessor}"
  end
end

def generate_android_core
  core_build = <<~KOTLIN
    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "com.multiplatformbusinesssdk.core"
        compileSdk = 34

        defaultConfig {
            minSdk = 26
        }

        publishing {
            singleVariant("release") {
                withSourcesJar()
            }
        }

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }
    }

    dependencies {
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.9.0")
    }
#{android_publish_snippet("business-sdk-android-core", "Business SDK Android Core", "Core networking primitives for generated Android SDK modules.")}
  KOTLIN

  core_source = <<~KOTLIN
    package com.multiplatformbusinesssdk.core

    import kotlinx.coroutines.sync.Mutex
    import kotlinx.coroutines.sync.withLock
    import org.json.JSONObject
    import java.io.IOException
    import java.net.HttpURLConnection
    import java.net.URL

    enum class HttpMethod {
        GET,
        POST,
        PUT,
        DELETE
    }

    sealed class NetworkError(message: String, cause: Throwable? = null) : Exception(message, cause) {
        class Url(cause: IOException) : NetworkError("URL error", cause)
        object InvalidResponse : NetworkError("Invalid HTTP response")
        object Unauthorized : NetworkError("Unauthorized")
        class HttpStatus(val code: Int, val payload: String) : NetworkError("Unexpected status: $code")
        object NoData : NetworkError("No data returned")
        class Decoding(cause: Throwable) : NetworkError("Decoding failed", cause)
    }

    interface TokenStore {
        suspend fun getAccessToken(): String?
        suspend fun refreshAccessToken()
        suspend fun clearTokens()
    }

    object NoOpTokenStore : TokenStore {
        override suspend fun getAccessToken(): String? = null
        override suspend fun refreshAccessToken() = Unit
        override suspend fun clearTokens() = Unit
    }

    class RefreshGate {
        private val mutex = Mutex()

        suspend fun refreshIfNeeded(operation: suspend () -> Unit) {
            mutex.withLock {
                operation()
            }
        }
    }

    interface ApiRequest<T> {
        val path: String
        val method: HttpMethod
        val body: ByteArray?
        val headers: Map<String, String>
        val query: Map<String, String>
        val requiresAuthorization: Boolean

        fun parse(payload: String): T
    }

    class NetworkEngine(
        private val baseUrl: String,
        private val tokenStore: TokenStore = NoOpTokenStore,
        private val refreshGate: RefreshGate = RefreshGate()
    ) {
        suspend fun <T> request(requestConfig: ApiRequest<T>): T {
            val url = buildUrl(requestConfig)
            return perform(url, requestConfig, didRetryAfterRefresh = false)
        }

        private suspend fun <T> perform(
            url: URL,
            requestConfig: ApiRequest<T>,
            didRetryAfterRefresh: Boolean
        ): T {
            val connection = (url.openConnection() as? HttpURLConnection) ?: throw NetworkError.InvalidResponse

            try {
                connection.requestMethod = requestConfig.method.name
                connection.instanceFollowRedirects = true
                requestConfig.headers.forEach { (key, value) -> connection.setRequestProperty(key, value) }

                if (requestConfig.requiresAuthorization) {
                    tokenStore.getAccessToken()?.let { token ->
                        connection.setRequestProperty("Authorization", "Bearer $token")
                    }
                }

                requestConfig.body?.let { body ->
                    connection.doOutput = true
                    connection.outputStream.use { stream -> stream.write(body) }
                }

                val statusCode = connection.responseCode
                val payload = readPayload(connection, statusCode)

                if (statusCode == 401) {
                    if (didRetryAfterRefresh) {
                        tokenStore.clearTokens()
                        throw NetworkError.Unauthorized
                    }

                    val hadAuthHeader = connection.getRequestProperty("Authorization") != null
                    if (!hadAuthHeader) {
                        throw NetworkError.Unauthorized
                    }

                    try {
                        refreshGate.refreshIfNeeded {
                            tokenStore.refreshAccessToken()
                        }
                    } catch (_: Throwable) {
                        tokenStore.clearTokens()
                        throw NetworkError.Unauthorized
                    }

                    val refreshedToken = tokenStore.getAccessToken() ?: run {
                        tokenStore.clearTokens()
                        throw NetworkError.Unauthorized
                    }

                    val retryHeaders = requestConfig.headers + mapOf("Authorization" to "Bearer $refreshedToken")
                    val retryRequest = object : ApiRequest<T> by requestConfig {
                        override val headers: Map<String, String> = retryHeaders
                    }
                    return perform(buildUrl(retryRequest), retryRequest, didRetryAfterRefresh = true)
                }

                if (statusCode !in 200..299) {
                    throw NetworkError.HttpStatus(statusCode, payload)
                }

                if (payload.isBlank()) {
                    throw NetworkError.NoData
                }

                return try {
                    requestConfig.parse(payload)
                } catch (error: Throwable) {
                    throw NetworkError.Decoding(error)
                }
            } catch (error: IOException) {
                throw NetworkError.Url(error)
            } finally {
                connection.disconnect()
            }
        }

        private fun <T> buildUrl(requestConfig: ApiRequest<T>): URL {
            val normalizedBaseUrl = baseUrl.trimEnd('/')
            val normalizedPath = requestConfig.path.trimStart('/')
            val query = if (requestConfig.query.isEmpty()) {
                ""
            } else {
                requestConfig.query.entries.joinToString(prefix = "?", separator = "&") { (key, value) ->
                    "${encode(key)}=${encode(value)}"
                }
            }
            return URL("$normalizedBaseUrl/$normalizedPath$query")
        }

        private fun encode(value: String): String = java.net.URLEncoder.encode(value, Charsets.UTF_8.name())

        private fun readPayload(connection: HttpURLConnection, statusCode: Int): String {
            val stream = if (statusCode in 200..299) connection.inputStream else connection.errorStream
            return stream?.bufferedReader()?.use { it.readText() }.orEmpty()
        }
    }
  KOTLIN

  write_file(File.join(ANDROID_DIR, "sdk-core", "build.gradle.kts"), core_build)
  write_file(File.join(ANDROID_DIR, "sdk-core", "src", "main", "java", "com", "multiplatformbusinesssdk", "core", "NetworkCore.kt"), core_source)
end

def generate_android_contract(contract)
  module_dir = File.join(ANDROID_MODULES_DIR, contract.fetch("android_module"))
  package_parts = contract.fetch("android_package").split(".")
  package_dir = File.join(module_dir, "src", "main", "java", *package_parts)

  build_gradle = <<~KOTLIN
    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "#{contract.fetch("android_package")}"
        compileSdk = 34

        defaultConfig {
            minSdk = 26
        }

        publishing {
            singleVariant("release") {
                withSourcesJar()
            }
        }

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }
    }

    dependencies {
        implementation(project(":sdk-core"))
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.9.0")
    }
#{android_publish_snippet("#{contract.fetch("android_module")}-android", "#{contract.fetch("name")} Android", "Generated Android business SDK for #{contract.fetch("name")}.")}
  KOTLIN

  models = contract.fetch("models").map do |model|
    fields = model.fetch("fields").map { |field| "    val #{field["name"]}: #{kotlin_type(field["type"])}" }.join(",\n")
    parse_lines = model.fetch("fields").map { |field| "            #{kotlin_model_field_parser(field).gsub("\n", "\n            ")}" }.join("\n")
    ctor_args = model.fetch("fields").map { |field| field["name"] }.join(", ")

    <<~KOTLIN
      data class #{model.fetch("name")}(
      #{fields}
      ) {
          companion object {
              fun fromJson(json: org.json.JSONObject): #{model.fetch("name")} {
                  #{parse_lines}
                  return #{model.fetch("name")}(#{ctor_args})
              }
          }
      }
    KOTLIN
  end.join("\n")

  repositories = contract.fetch("repositories")
  request_classes = repositories.flat_map do |repository|
    repository.fetch("methods").map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      ctor_params = params.map do |param|
        default = kotlin_default_value(param)
        default ? "private val #{param["name"]}: #{kotlin_type(param["type"])} = #{default}" : "private val #{param["name"]}: #{kotlin_type(param["type"])}"
      end.join(", ")
      headers = contract.fetch("default_headers", {}).map { |key, value| "\"#{key}\" to \"#{value}\"" }.join(", ")
      header_map = headers.empty? ? "emptyMap()" : "mapOf(#{headers})"
      request_name = "#{repository.fetch("name")}#{pascal_case(method.fetch("name"))}Request"

      <<~KOTLIN
        private class #{request_name}(#{ctor_params}) : ApiRequest<#{method.fetch("response")}> {
            override val path: String = #{kotlin_path_expression(method.fetch("path"), method["path_params"])}
            override val method: HttpMethod = HttpMethod.#{method.fetch("method")}
            override val body: ByteArray? = null
            override val headers: Map<String, String> = #{header_map}
            override val query: Map<String, String> = #{render_kotlin_query_map(method["query_params"])}
            override val requiresAuthorization: Boolean = #{method.fetch("requires_authorization", false) ? "true" : "false"}

            override fun parse(payload: String): #{method.fetch("response")} =
                #{method.fetch("response")}.fromJson(org.json.JSONObject(payload))
        }
      KOTLIN
    end
  end.join("\n")

  repository_types = repositories.map do |repository|
    methods = repository.fetch("methods")

    interface_methods = methods.map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      signature = params.map do |param|
        default = kotlin_default_value(param)
        default ? "#{param["name"]}: #{kotlin_type(param["type"])} = #{default}" : "#{param["name"]}: #{kotlin_type(param["type"])}"
      end.join(", ")
      "    suspend fun #{method.fetch("name")}(#{signature}): #{method.fetch("response")}"
    end.join("\n")

    impl_methods = methods.map do |method|
      params = Array(method["path_params"]) + Array(method["query_params"])
      signature = params.map do |param|
        default = kotlin_default_value(param)
        default ? "#{param["name"]}: #{kotlin_type(param["type"])} = #{default}" : "#{param["name"]}: #{kotlin_type(param["type"])}"
      end.join(", ")
      invocation = params.map { |param| "#{param["name"]} = #{param["name"]}" }.join(", ")
      request_name = "#{repository.fetch("name")}#{pascal_case(method.fetch("name"))}Request"

      <<~KOTLIN
        override suspend fun #{method.fetch("name")}(#{signature}): #{method.fetch("response")} {
            return networkEngine.request(#{request_name}(#{invocation}))
        }
      KOTLIN
    end.join("\n")

    <<~KOTLIN
      interface #{repository.fetch("name")}Protocol {
      #{interface_methods}
      }

      class #{repository.fetch("name")}(
          private val networkEngine: NetworkEngine
      ) : #{repository.fetch("name")}Protocol {
      #{impl_methods}
      }
    KOTLIN
  end.join("\n")

  sdk_protocol_properties = repositories.map do |repository|
    "    val #{lower_camel_case(repository.fetch("name"))}: #{repository.fetch("name")}Protocol"
  end.join("\n")

  sdk_impl_properties = repositories.map do |repository|
    property_name = lower_camel_case(repository.fetch("name"))
    "    override val #{property_name}: #{repository.fetch("name")}Protocol = #{repository.fetch("name")}(networkEngine)"
  end.join("\n")

  source = <<~KOTLIN
    package #{contract.fetch("android_package")}

    import com.multiplatformbusinesssdk.core.ApiRequest
    import com.multiplatformbusinesssdk.core.HttpMethod
    import com.multiplatformbusinesssdk.core.NetworkEngine

    object #{contract.fetch("swift_module")}Config {
        const val baseUrl: String = "#{contract.fetch("base_url")}"
    }

    #{models}

    #{request_classes}

    #{repository_types}

    interface #{contract.fetch("swift_module")}ClientProtocol {
    #{sdk_protocol_properties}
    }

    class #{contract.fetch("swift_module")}Client(
        networkEngine: NetworkEngine = NetworkEngine(baseUrl = #{contract.fetch("swift_module")}Config.baseUrl)
    ) : #{contract.fetch("swift_module")}ClientProtocol {
    #{sdk_impl_properties}
    }
  KOTLIN

  write_file(File.join(module_dir, "build.gradle.kts"), build_gradle)
  write_file(File.join(package_dir, "#{contract.fetch("swift_module")}.kt"), source)
end

def generate_android_umbrella(contracts)
  dependencies = ["api(project(\":sdk-core\"))"] + contracts.map { |contract| "api(project(\":modules:#{contract.fetch("android_module")}\"))" }
  build_gradle = <<~KOTLIN
    plugins {
        id("com.android.library")
        kotlin("android")
        id("maven-publish")
    }

    android {
        namespace = "#{ANDROID_GROUP_ID}"
        compileSdk = 34

        defaultConfig {
            minSdk = 26
        }

        publishing {
            singleVariant("release") {
                withSourcesJar()
            }
        }

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }
    }

    dependencies {
        #{dependencies.join("\n        ")}
    }
#{android_publish_snippet("business-sdk-android", "Business SDK Android", "Umbrella Android package exposing all generated SDK modules from this repository.")}
  KOTLIN

  source = <<~KOTLIN
    package #{ANDROID_GROUP_ID}

    public object BusinessSDKPackage
  KOTLIN

  write_file(File.join(ANDROID_UMBRELLA_DIR, "build.gradle.kts"), build_gradle)
  write_file(File.join(ANDROID_UMBRELLA_DIR, "src", "main", "java", "com", "multiplatformbusinesssdk", "BusinessSDKPackage.kt"), source)
end

def generate_android_settings(contracts)
  includes = [":sdk-core", ":business-sdk"] + contracts.map { |contract| ":modules:#{contract.fetch("android_module")}" }
  project_lines = contracts.map do |contract|
    module_name = contract.fetch("android_module")
    "project(\":modules:#{module_name}\").projectDir = file(\"modules/#{module_name}\")"
  end

  <<~KOTLIN
    pluginManagement {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }

    dependencyResolutionManagement {
        repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
        repositories {
            google()
            mavenCentral()
        }
    }

    rootProject.name = "MultiPlatformBusinessSDK"
    #{includes.map { |include_line| "include(\"#{include_line}\")" }.join("\n")}
    project(":business-sdk").projectDir = file("business-sdk")
    #{project_lines.join("\n")}
  KOTLIN
end

def generate_android_root_build
  <<~KOTLIN
    plugins {
        id("com.android.library") version "8.5.2" apply false
        kotlin("android") version "2.0.21" apply false
        id("maven-publish") apply false
    }
  KOTLIN
end

def generate_android_gradle_properties
  <<~PROPERTIES
    org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
    android.useAndroidX=true
    kotlin.code.style=official
  PROPERTIES
end

contracts = read_contracts

cleanup_generated_directories(contracts)

write_file(File.join(ROOT, "Package.swift"), generate_package_swift(contracts, source_root: "BusinessSDK/Sources", tests_root: "BusinessSDK/Tests"))
write_file(File.join(IOS_DIR, "Package.swift"), generate_package_swift(contracts))
write_file(File.join(IOS_SOURCES_DIR, "BusinessSDKCore", "NetworkCore.swift"), generate_swift_core)
write_file(File.join(IOS_SOURCES_DIR, "BusinessSDK", "BusinessSDK.swift"), generate_swift_umbrella(contracts))
write_file(File.join(IOS_TESTS_DIR, "BusinessSDKTests.swift"), generate_tests(contracts))

contracts.each do |contract|
  write_file(File.join(IOS_SOURCES_DIR, contract.fetch("swift_module"), "#{contract.fetch("swift_module")}.swift"), swift_repository(contract))
end

ensure_dir(ANDROID_DIR)
write_file(File.join(ANDROID_DIR, "settings.gradle.kts"), generate_android_settings(contracts))
write_file(File.join(ANDROID_DIR, "build.gradle.kts"), generate_android_root_build)
write_file(File.join(ANDROID_DIR, "gradle.properties"), generate_android_gradle_properties)
generate_android_core
contracts.each { |contract| generate_android_contract(contract) }
generate_android_umbrella(contracts)
write_file(File.join(DOCS_DIR, "SDK_CATALOG.md"), generate_contract_docs(contracts))

puts "Generated SDKs for #{contracts.size} contract(s)."
