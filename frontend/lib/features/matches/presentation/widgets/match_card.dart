import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/match.dart';

/// MatchCard — heart of the app UI.
///
/// States handled:
///   - scheduled:  shows kickoff countdown + H2H panel
///   - live:       glowing green dot + live score
///   - finished:   dimmed header + final score + user result badge
///
/// All transitions are animated; haptic feedback fires on bet submit.
class MatchCard extends StatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.userBet,
    this.onBetSubmit,
    this.isExpanded = false,
  });

  final Match match;
  final Bet?  userBet;
  final void Function(int home, int away)? onBetSubmit;
  final bool isExpanded;

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double>   _expandAnimation;

  bool _showBetInput = false;
  final _homeCtrl = TextEditingController();
  final _awayCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
    if (widget.isExpanded) _expandController.value = 1.0;
  }

  @override
  void dispose() {
    _expandController.dispose();
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------

  void _toggleExpand() {
    if (_expandController.isCompleted) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
    HapticFeedback.selectionClick();
  }

  void _submitBet() {
    final home = int.tryParse(_homeCtrl.text);
    final away = int.tryParse(_awayCtrl.text);
    if (home == null || away == null) return;

    HapticFeedback.mediumImpact();
    widget.onBetSubmit?.call(home, away);
    setState(() => _showBetInput = false);
  }

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Glassmorphism base
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompetitionHeader(match: widget.match),
            _TeamsRow(match: widget.match, userBet: widget.userBet),
            if (widget.match.status == MatchStatus.live) const _LiveIndicator(),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const _Divider(),
                  _H2HPanel(match: widget.match),
                  if (widget.match.status == MatchStatus.scheduled &&
                      widget.onBetSubmit != null) ...[
                    const _Divider(),
                    _BetInputRow(
                      homeCtrl: _homeCtrl,
                      awayCtrl: _awayCtrl,
                      onSubmit: _submitBet,
                    ),
                  ],
                ],
              ),
            ),
            _ExpandButton(
              isExpanded: _expandController.isCompleted,
              onTap: _toggleExpand,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Sub-widgets
// ===========================================================================

class _CompetitionHeader extends StatelessWidget {
  const _CompetitionHeader({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _LeagueLogo(url: match.competition.logoUrl),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${match.competition.name}  ·  ${match.round ?? ""}',
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _KickoffChip(match: match),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TeamsRow extends StatelessWidget {
  const _TeamsRow({required this.match, this.userBet});
  final Match match;
  final Bet?  userBet;

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    final isLive     = match.status == MatchStatus.live;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(child: _TeamInfo(team: match.homeTeam, align: CrossAxisAlignment.start)),
          _ScoreOrVS(match: match, isFinished: isFinished, isLive: isLive),
          Expanded(child: _TeamInfo(team: match.awayTeam, align: CrossAxisAlignment.end)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ScoreOrVS extends StatelessWidget {
  const _ScoreOrVS({
    required this.match,
    required this.isFinished,
    required this.isLive,
  });

  final Match match;
  final bool  isFinished;
  final bool  isLive;

  @override
  Widget build(BuildContext context) {
    if (isFinished || isLive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreDigit(value: match.homeScoreFt ?? 0, highlight: isLive),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–', style: AppTextStyles.scoreVs),
              ),
              _ScoreDigit(value: match.awayScoreFt ?? 0, highlight: isLive),
            ],
          ),
          if (isFinished)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Final', style: AppTextStyles.caption),
            ),
        ],
      );
    }

    return Text('VS', style: AppTextStyles.scoreVs);
  }
}

// ---------------------------------------------------------------------------

class _ScoreDigit extends StatelessWidget {
  const _ScoreDigit({required this.value, this.highlight = false});
  final int  value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: AppTextStyles.scoreDigit.copyWith(
        color: highlight ? AppColors.liveGreen : AppColors.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TeamInfo extends StatelessWidget {
  const _TeamInfo({required this.team, required this.align});
  final Team              team;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final isStart = align == CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        _TeamLogo(url: team.logoUrl),
        const SizedBox(height: 8),
        Text(
          team.shortName ?? team.name,
          style: AppTextStyles.teamName,
          textAlign: isStart ? TextAlign.left : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.liveGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('AO VIVO', style: AppTextStyles.liveBadge),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _H2HPanel extends StatelessWidget {
  const _H2HPanel({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final h2h = match.h2hStats;
    if (h2h == null) return const SizedBox.shrink();

    final total = (h2h.teamAWins + h2h.draws + h2h.teamBWins).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confronto Direto (últimos ${h2h.lastNMatches})',
              style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _H2HBar(
                  label: '${match.homeTeam.shortName ?? match.homeTeam.name} ${h2h.teamAWins}',
                  flex: total > 0 ? (h2h.teamAWins / total) : 0,
                  color: AppColors.winHome,
                  alignLeft: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${h2h.draws} E', style: AppTextStyles.caption),
              ),
              Expanded(
                child: _H2HBar(
                  label: '${h2h.teamBWins} ${match.awayTeam.shortName ?? match.awayTeam.name}',
                  flex: total > 0 ? (h2h.teamBWins / total) : 0,
                  color: AppColors.winAway,
                  alignLeft: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Gols: ${h2h.teamAGoals} – ${h2h.teamBGoals}',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _H2HBar extends StatelessWidget {
  const _H2HBar({
    required this.label,
    required this.flex,
    required this.color,
    required this.alignLeft,
  });

  final String label;
  final double flex;
  final Color  color;
  final bool   alignLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: flex,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _BetInputRow extends StatelessWidget {
  const _BetInputRow({
    required this.homeCtrl,
    required this.awayCtrl,
    required this.onSubmit,
  });

  final TextEditingController homeCtrl;
  final TextEditingController awayCtrl;
  final VoidCallback           onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          _ScoreInput(controller: homeCtrl, label: 'Casa'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('–', style: TextStyle(color: AppColors.textSecondary, fontSize: 20)),
          ),
          _ScoreInput(controller: awayCtrl, label: 'Fora'),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Palpitar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  const _ScoreInput({required this.controller, required this.label});
  final TextEditingController controller;
  final String                 label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        style: AppTextStyles.teamName,
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: AppTextStyles.caption,
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.isExpanded, required this.onTap});
  final bool     isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Micro-widgets
// ---------------------------------------------------------------------------

class _LeagueLogo extends StatelessWidget {
  const _LeagueLogo({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: AppColors.cardBorder,
      backgroundImage: url != null ? NetworkImage(url!) : null,
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.cardBorder,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? const Icon(Icons.sports_soccer, color: AppColors.textSecondary)
          : null,
    );
  }
}

class _KickoffChip extends StatelessWidget {
  const _KickoffChip({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final label = match.status == MatchStatus.scheduled
        ? _formatKickoff(match.kickoffAt)
        : match.status == MatchStatus.live
            ? 'AO VIVO'
            : 'FIM';

    final color = match.status == MatchStatus.live
        ? AppColors.liveGreen
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }

  static String _formatKickoff(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.cardBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}
