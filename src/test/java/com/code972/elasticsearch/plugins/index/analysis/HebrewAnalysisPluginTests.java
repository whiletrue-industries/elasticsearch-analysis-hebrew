/*
 * HebMorph's elasticsearch-analysis-hebrew
 * Copyright (C) 2010-2017 Itamar Syn-Hershko
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.code972.elasticsearch.plugins.index.analysis;

import com.code972.elasticsearch.HebrewAnalysisPlugin;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.plugins.Plugin;
import org.elasticsearch.test.ESTestCase;

/**
 * Basic unit test for Hebrew Analysis Plugin
 */
public class HebrewAnalysisPluginTests extends ESTestCase {

    public void testPluginInstantiation() throws Exception {
        // Test that the plugin can be instantiated
        Settings settings = Settings.builder()
                .put("path.home", createTempDir())
                .build();

        HebrewAnalysisPlugin plugin = new HebrewAnalysisPlugin(settings, createTempDir());
        assertNotNull("Plugin should be instantiated", plugin);

        // Verify plugin provides the expected components
        assertNotNull("Plugin should provide token filters", plugin.getTokenFilters());
        assertFalse("Plugin should have token filters", plugin.getTokenFilters().isEmpty());

        assertNotNull("Plugin should provide tokenizers", plugin.getTokenizers());
        assertFalse("Plugin should have tokenizers", plugin.getTokenizers().isEmpty());

        assertNotNull("Plugin should provide analyzers", plugin.getAnalyzers());
        assertFalse("Plugin should have analyzers", plugin.getAnalyzers().isEmpty());

        assertNotNull("Plugin should provide settings", plugin.getSettings());
        assertFalse("Plugin should have settings", plugin.getSettings().isEmpty());
    }
}
