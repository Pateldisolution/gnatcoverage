import qm
from qm.rest import ArtifactImporter, writer
from qm.rest.pdfgenerator import artifact_hash
import re


def class_to_string(a):

    d = {'TORReq_Set': 'rqg',
         'HReq_Set': 'rqg',
         'TORReq': 'rq',
         'HReq': 'rq',
         'TORTC': 'tc',
         'HTC': 'tc',
         'TORTC_Set': 'tcg',
         'HTC_Set': 'tcg'}
    if 'Appendix' in a.full_name:
        return 'app'
    elif a.name == 'OpEnviron':
        return 'env'
    elif a.__class__.__name__ in d:
        return d[a.__class__.__name__]
    else:
        return a.__class__.__name__


def is_test(a):
    from qm import TC, TC_Set
    return isinstance(a, TC) or isinstance(a, TC_Set)


def is_source(a):
    from qm import TC_Sources
    return isinstance(a, TC_Sources)


class TCIndexImporter(ArtifactImporter):

    def get_recursive_relatives(self, artifact, depth):
        result = []

        for child in artifact.relatives:
            if is_test(child):
                result.append(child)
                if depth > 1:
                    result += self.get_recursive_relatives(child, depth - 1)

        return result

    def qmlink_to_rest(self, parent, artifacts):
        from qm import TC
        html_items = []
        pdf_items = []
        output = ''

        for a in artifacts:
            # Don't put sources in the tables
            if is_source(a):
                continue

            html_items.append([writer.strong(class_to_string(a)),
                               writer.strong(a.name),
                               writer.qmref(a.full_name)])
            pdf_items.append([class_to_string(a),
                              a.name,
                              writer.qmref(a.full_name)])
            for suba in self.get_recursive_relatives(a, 1):
                # We do include in the table children artifacts only
                # in html format.
                html_items.append([class_to_string(suba),
                                   "``..`` " + suba.name,
                                   writer.qmref(suba.full_name)])

        html_table = writer.csv_table(
            html_items,
            headers=["", "TestCases", "Description"],
            widths=[3, 25, 65])

        pdf_table = writer.csv_table(
            pdf_items,
            headers=["", "TestCases", "Description"],
            widths=[3, 25, 65])

        output += writer.only(html_table, "html")
        output += writer.only(pdf_table, "latex")

        links = []
        for a in artifacts:
            if isinstance(a, TC):
                links.append((a, TestCaseImporter()))
            elif is_source(a):
                pass
            else:
                links.append((a, qm.rest.DefaultImporter()))

        output += writer.toctree(['/%s/content' % artifact_hash(*l)
                                  for l in links if
                                  not is_test(l[0]) or is_test(parent)],
                                 hidden=True)
        return output, links


class AppIndexImporter(ArtifactImporter):

    def qmlink_to_rest(self, parent, artifacts):
        return '', []


class ToplevelIndexImporter(ArtifactImporter):

    def qmlink_to_rest(self, parent, artifacts):
        items = []
        html_top_index = ""

        for a in artifacts:

            if a.full_name == "/TOR_Doc/Introduction":
                for item in a.contents('content'):
                    html_top_index += writer.paragraph (item.get_content())

            else:
                items.append([writer.strong(class_to_string(a)),
                             writer.strong(a.name),
                             writer.qmref(a.full_name)])
                for suba in a.relatives:
                    items.append([class_to_string(suba),
                                 "``..`` " + suba.name,
                                 writer.qmref(suba.full_name)])

        html_top_index += writer.csv_table(
            items,
            headers=["", "Chapter", "Description"],
            widths=[3, 25, 65])

        output = writer.only(html_top_index, "html")

        links = [(a, qm.rest.DefaultImporter()) for a in artifacts]

        output += writer.toctree(['/%s/content' % artifact_hash(*l)
                                  for l in links if not is_test(l[0])],
                                 hidden=True)

        return output, links


class SubsetIndexImporter(ArtifactImporter):

    def qmlink_to_rest(self, parent, artifacts):

        items = []
        header = ""

        req = len([a for a in artifacts if class_to_string(a) == 'rq'])
        reqg = len([a for a in artifacts if class_to_string(a) == 'rqg'])

        for a in artifacts:

            name = re.sub(r'[0-9]*_(.*)', r'\1', a.name)
            items.append([class_to_string(a),
                          name,
                          writer.qmref(a.full_name)])

        # in the html, the title is adapted to the content of the table
        header = ("Requirements and Groups" if (req > 0 and reqg > 0) else
                  ("Requirements Group" if (req == 0 and reqg == 1) else
                   ("Requirements Groups" if (req == 0 and reqg > 1) else
                    ("Requirement" if (req == 1 and reqg == 0) else
                     ("Requirements" if (req > 1 and reqg == 0) else
                      "")))))

        html_output = writer.csv_table(
            items,
            headers=["", "%s" % header, "Description"],
            widths=[3, 25, 65])

        # for latex, all the tables keep the same title
        latex_output = writer.csv_table(
            items,
            headers=["", "Requirements or Groups", "Description"],
            widths=[3, 25, 65])

        output = writer.only(html_output, "html")
        output += writer.only(latex_output, "latex")

        links = [(a, qm.rest.DefaultImporter()) for a in artifacts]

        output += writer.toctree(['/%s/content' % artifact_hash(*l)
                                  for l in links if not is_test(l[0])],
                                 hidden=True)

        return output, links


class TestCaseImporter(ArtifactImporter):

    def get_sources(self, artifact):
        result = []

        for child in artifact.relatives:
            if is_source(child):
                result += [child]

        if is_test(artifact.relative_to):
            result += self.get_sources(artifact.relative_to)

        return result

    def to_rest(self, artifact):

        result = qm.rest.DefaultImporter().to_rest(artifact) + '\n\n'
        result += writer.subsection("sources")

        for item in self.get_sources(artifact):

            for key in item.contents_keys:
                if len(item.contents(key)) > 0:

                    basename_list = [k.basename for k in item.contents(key)]
                    qmref_source_list = [writer.qmref
                                         (item.full_name, k.basename)
                                         for k in item.contents(key)]

                    result += writer.only(
                        writer.generic_list(qmref_source_list),
                        "html")
                    result += writer.only(
                        writer.generic_list(basename_list),
                        "latex")

        return result


class SourceCodeImporter(ArtifactImporter):

    def to_rest(self, artifact):

        from qm import Ada_Sources, C_Sources

        result = ""

        if isinstance(artifact, Ada_Sources):

            for key in artifact.contents_keys:
                for item in artifact.contents(key):
                    result += writer.paragraph_title(item.basename)
                    result += writer.code_block(item.get_content(), "ada")

        if isinstance(artifact, C_Sources):

            for key in artifact.contents_keys:
                for item in artifact.contents(key):
                    result += writer.paragraph_title(item.basename)
                    result += writer.code_block(item.get_content(), "c")

        return result


class TestCasesImporter(ArtifactImporter):

    def get_testcases(self, artifact):
        result = []

        if is_test(artifact):
            return [artifact]

        for child in artifact.relatives:
            result += self.get_testcases(child)

        return result

    def get_sources(self, artifact):
        result = []

        if is_source(artifact):
            return [artifact]

        for child in artifact.relatives:
            result += self.get_sources(child)

        return result

    def qmlink_to_rest(self, parent, artifacts):

        from qm import TC_Sources, TC

        items = []
        for a in artifacts:
            items += self.get_testcases(a)
            items += self.get_sources(a)

        links = []
        for a in items:
            if isinstance(a, TC):
                links.append((a, TestCaseImporter()))
            if isinstance(a, TC_Sources):
                links.append((a, SourceCodeImporter()))
            else:
                links.append((a, qm.rest.DefaultImporter()))

        html_output = writer.toctree(['/%s/content' % artifact_hash(*l)
                                      for l in links], hidden=True)

        # We don't include the tests sources in the pdf version
        pdf_output = writer.section ('Test Cases') + '\n'
        pdf_output += writer.toctree(['/%s/content' % artifact_hash(*l)
                                     for l in links if not is_source(l[0])],
                                    hidden=True)
        output = writer.only(html_output, "html")
        output += writer.only(pdf_output, "latex")

        return output, links