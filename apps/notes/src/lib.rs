// SPDX-FileCopyrightText: 2026 Veydan Project
// SPDX-License-Identifier: LicenseRef-PolyForm-Perimeter-1.0.1

//! Veydan Notes: the product crate (internal/platform-spec.md 13.1). It holds
//! the Tauri config, the strings of the product and the list of its
//! modules — one, the crate of notes; `veydan_shell` starts it, and the
//! plan of its sync is the shell's default over what the module registers
//! (9.1). The identifier `net.veydan.notes` and the version (`VERSION`,
//! written by `scripts/set-version.sh notes`) are in the Tauri config.
//!
//! One library for every platform: a computer and a phone run the same
//! module.

use veydan_shell::{Module, Product};

/// What Notes is (13.1, 13.5).
fn product() -> Product {
    Product {
        id: "notes",
        name: "Veydan Notes",
        desktop_entry: "veydannotes",
        icon: "veydannotes",
        sync: veydan_shell::default_plan(&module_list()),
    }
}

/// The modules of Notes, as `products.json` lists them.
pub fn module_list() -> Vec<Module> {
    vec![veydan_notes::module()]
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    veydan_shell::run(tauri::generate_context!(), product(), module_list());
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The modules of the crate are those `products.json` gives the
    /// product: the UI is built from that list, the app from this one.
    #[test]
    fn the_module_list_is_that_of_products_json() {
        let manifest: serde_json::Value =
            serde_json::from_str(include_str!("../../../products.json")).unwrap();
        let listed: Vec<&str> = manifest["targets"]["notes"]["modules"]
            .as_array()
            .unwrap()
            .iter()
            .map(|id| id.as_str().unwrap())
            .collect();
        let ours: Vec<&str> = module_list().iter().map(|module| module.id).collect();
        assert_eq!(ours, listed);
    }

    /// `commands.golden.txt`: every command of the product on a line with
    /// the module that answers it and where it exists (`all` platforms or
    /// `desktop` only), the lines of Space's file that belong to the shell
    /// and to notes. A name neither appears nor disappears without a
    /// matching change in the UI.
    #[test]
    fn every_command_has_the_owner_the_golden_file_names() {
        let expected: Vec<(&str, &str)> = include_str!("commands.golden.txt")
            .lines()
            .map(|line| {
                let mut words = line.split(' ');
                let (command, module, platform) = (
                    words.next().unwrap(),
                    words.next().unwrap(),
                    words.next().unwrap(),
                );
                assert!(matches!(platform, "all" | "desktop"), "{line}");
                (command, module, platform)
            })
            .filter(|(_, _, platform)| cfg!(desktop) || *platform == "all")
            .map(|(command, module, _)| (command, module))
            .collect();
        let table = veydan_shell::command_table(product(), module_list()).unwrap();
        for line in &table {
            assert!(expected.contains(line), "not in the golden file: {line:?}");
        }
        for line in &expected {
            assert!(table.contains(line), "the router does not know {line:?}");
        }
        assert_eq!(table.len(), expected.len());
    }

    /// The default plan takes everything the module and the shell register,
    /// in the order of 9.1: the system rows and the catalog of the notes,
    /// the attachments and the notes themselves, the flags of a note after
    /// it, the labels last. Neither handler has a late part, so each entity
    /// is applied once and `late` is empty. A phone syncs no settings.
    #[test]
    fn the_plan_applies_the_catalog_before_the_notes_and_the_flags_after() {
        let registry = veydan_shell::sync_registry(product(), module_list()).unwrap();
        let (puts, _) = registry.apply_order();
        #[cfg(desktop)]
        let expected = [
            "password_vault",
            "setting",
            "note_tag",
            "note_folder",
            "note_smart_view",
            "note_attachment",
            "note_attachment_v2",
            "note",
            "note_meta",
            "label",
        ];
        #[cfg(mobile)]
        let expected = [
            "password_vault",
            "note_tag",
            "note_folder",
            "note_smart_view",
            "note_attachment",
            "note_attachment_v2",
            "note",
            "note_meta",
            "label",
        ];
        assert_eq!(puts, expected);
        assert!(product().sync.late.is_empty());
        let mut handlers = registry.handler_names();
        handlers.sort_unstable();
        assert_eq!(handlers, ["attachments", "notes"]);
    }

    /// The data file of Notes: the core's, the lock's and sync's tables,
    /// and the notes'. No table of pass, browser or ssh.
    #[test]
    fn the_schemas_are_the_cores_and_the_notes() {
        let mut names: Vec<_> = veydan_shell::schemas(&module_list())
            .iter()
            .map(|schema| schema.module)
            .collect();
        names.sort_unstable();
        assert_eq!(names, ["core", "lock", "notes", "sync"]);
    }
}
