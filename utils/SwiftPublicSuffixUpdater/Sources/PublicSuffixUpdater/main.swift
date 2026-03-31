/* *************************************************************************************************
 main.swift
  © 2020,2026 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import PublicSuffixUpdaterLibrary
import yCodeUpdater

let manager = CodeUpdaterManager()
manager.updaters = [
  .init(delegate: PublicSuffixList())
]

await manager.run()
