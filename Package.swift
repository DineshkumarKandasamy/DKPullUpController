// swift-tools-version: 5.9
//
//  Package.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import PackageDescription

let package = Package(
    name: "DKPullUpController",
    platforms: [.iOS(.v17)],
    products: [.library(name: "DKPullUpController", targets: ["DKPullUpController"])],
    targets: [.target(name: "DKPullUpController")]
)
